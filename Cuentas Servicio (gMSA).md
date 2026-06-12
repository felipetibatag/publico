
## Configurar la infraestructura gMSA en el DC

Crear la clave KDS Root Key saltándose las 10 horas de espera (Solo para laboratorios)
~~~powershell
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
~~~
## Crear la cuenta gMSA en Active Directory

El parámetro `-PrincipalsAllowedToRetrieveManagedPassword` le dice a AD qué equipos tienen derecho a pedir la contraseña de esta cuenta. Ponemos tu DC por ahora.

~~~powershell
New-ADServiceAccount -Name "gmsa-tareas" `
                     -DNSHostName "gmsa-tareas.miscositas.local" `
                     -PrincipalsAllowedToRetrieveManagedPassword "equipo1$" `
                     -Enabled $true
~~~
## Instalar y Validar la cuenta en el Servidor (equipo1)
 Una vez creada la cuenta en el dominio toca asociarla físicamente al sistema operativo del servidor donde se usara la cuenta gMSA:

~~~powershell
#Cargar en memoria la librería de .NET para gestión de cuentas de Active Directory
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

#Definir las variables de tu entorno
$gMSA_Account = "gmsa-tareas$"
$DomainName   = "miscositas.local"

#Inicializar el contexto de .NET para conectar el Windows 11 con el Dominio
$Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $DomainName)
$MachineContext = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context, $env:COMPUTERNAME)

#Limpiar la tabla de tickets Kerberos local para forzar la lectura del nuevo canal
& klist.exe purge

#Verificar el canal seguro de confianza con el DC (Devolvió NERR_Success)
nltest /sc_verify:miscositas.local
~~~

Definir la acción de la tarea programada (Ejemplo de prueba)
~~~powershell
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\cmd.exe" -Argument "/c echo Prueba gMSA > C:\Windows\Temp\gmsa_test.txt"

#Definir el disparador (Trigger) de la tarea
$Trigger = New-ScheduledTaskTrigger -At 1am -Daily

#Crear el perfil de seguridad amarrado a la gMSA usando LogonType 'Password'
$Principal = New-ScheduledTaskPrincipal -UserId "MISCOSITAS\gmsa-tareas$" -LogonType Password -RunLevel Highest

#Registrar y activar la tarea en el sistema operativo local
Register-ScheduledTask -TaskName "Tarea_gMSA_PowerShell" -Action $Action -Trigger $Trigger -Principal $Principal
~~~

Comando para ver desde el DC que cuentas de servicio están asociadas a qué equipo:
~~~powershell
Get-ADServiceAccount -Identity "gmsa-tareas" -Properties PrincipalsAllowedToRetrieveManagedPassword

DistinguishedName                          : CN=gmsa-tareas,CN=Managed Service Accounts,DC=miscositas,DC=local
Enabled                                    : True
Name                                       : gmsa-tareas
ObjectClass                                : msDS-GroupManagedServiceAccount
ObjectGUID                                 : fbebb750-e8f6-4e43-9475-cc4b3f91cac9
PrincipalsAllowedToRetrieveManagedPassword : {CN=CLI-EQUIPOW1101,OU=Equipos,OU=Corporativo,DC=miscositas,DC=local}
SamAccountName                             : gmsa-tareas$
SID                                        : S-1-5-21-4290043354-570584518-2596911422-1122
UserPrincipalName                          : 
~~~
