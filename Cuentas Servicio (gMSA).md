
### 🛠️ Paso 1: Configurar la infraestructura gMSA en tu `DC01`
# 1. Crear la clave KDS Root Key saltándose las 10 horas de espera (Solo para laboratorios)
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

# 2. Crear la cuenta gMSA en Active Directory
# Nota: El parámetro -PrincipalsAllowedToRetrieveManagedPassword le dice a AD 
# qué equipos tienen derecho a pedir la contraseña de esta cuenta. Ponemos tu DC por ahora.
New-ADServiceAccount -Name "gmsa-tareas" `
                     -DNSHostName "gmsa-tareas.miscositas.local" `
                     -PrincipalsAllowedToRetrieveManagedPassword "DC01$" `
                     -Enabled $true
 ### 🛠️ Paso 2: Instalar y Validar la cuenta en el Servidor (`DC01`)
 Una vez creada en el dominio, debes "asociarla" físicamente al sistema operativo del servidor donde se va a usar la tarea programada. Ejecuta esto en el mismo DC, para no instalar las RSAT

# 1. Cargar en memoria la librería de .NET para gestión de cuentas de Active Directory
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

# 2. Definir las variables de tu entorno
$gMSA_Account = "gmsa-tareas$"
$DomainName   = "miscositas.local"

# 3. Inicializar el contexto de .NET para conectar el Windows 11 con el Dominio
$Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $DomainName)
$MachineContext = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context, $env:COMPUTERNAME)

# 4. Limpiar la tabla de tickets Kerberos local para forzar la lectura del nuevo canal
& klist.exe purge

# A. Verificar el canal seguro de confianza con el DC (Devolvió NERR_Success)
nltest /sc_verify:miscositas.local

# B. Definir la acción de la tarea programada (Ejemplo de prueba)
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\cmd.exe" -Argument "/c echo Prueba gMSA > C:\Windows\Temp\gmsa_test.txt"

# C. Definir el disparador (Trigger) de la tarea
$Trigger = New-ScheduledTaskTrigger -At 1am -Daily

# D. Crear el perfil de seguridad amarrado a la gMSA usando LogonType 'Password'
$Principal = New-ScheduledTaskPrincipal -UserId "MISCOSITAS\gmsa-tareas$" -LogonType Password -RunLevel Highest

# E. Registrar y activar la tarea en el sistema operativo local
Register-ScheduledTask -TaskName "Tarea_gMSA_PowerShell" -Action $Action -Trigger $Trigger -Principal $Principal

Comando para ver desde el DC que cuentas de servicio están asociadas a qué equipo
Get-ADServiceAccount -Identity "gmsa-tareas" -Properties PrincipalsAllowedToRetrieveManagedPassword 