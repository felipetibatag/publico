Esto se conforma de dos archivos que deben estar definidos en un módulo:
- Capacidad rol (\*.pscr): Acá se define **qué** se puede hacer.
- Configuración de sesión (\*.pssc): Define **quién** lo puede hacer

## Crear carpeta módulo
~~~powershell
Invoke-Command -ComputerName CLI-EQUIPOW1101.miscositas.local -ScriptBlock {
    $Path = "C:\Program Files\WindowsPowerShell\Modules\LaboratorioJEA"
    New-Item -ItemType Directory -Path "$Path\RoleCapabilities" -Force
}
~~~
## Crear archivo PSCR (Qué se puede hacer)
Por ejemplo definir que solo pueda usar el cmdlet start-service, stop-service y restart-service, pero únicamente sobre el servicio de Windows Update (***wuauserv***):

~~~powershell
Invoke-Command -ComputerName CLI-EQUIPOW1101.miscositas.local -ScriptBlock {
    $RolePath = "C:\Program Files\WindowsPowerShell\Modules\LaboratorioJEA\RoleCapabilities\OperadorSoporte.psrc"
    
    $RoleContent = @'
@{
    # VisibleCmdlets define qué comandos y qué parámetros específicos se permiten
    VisibleCmdlets = @(
        @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = @('wuauserv') } },
        @{ Name = 'Start-Service';   Parameters = @{ Name = 'Name'; ValidateSet = @('wuauserv') } },
        @{ Name = 'Stop-Service';    Parameters = @{ Name = 'Name'; ValidateSet = @('wuauserv') } },
        @{ Name = 'Get-Service';     Parameters = @{ Name = 'Name'; ValidateSet = @('wuauserv') } }
    )
	# Agregar los ejecutables externos que no son nativos de Powershell restringiendo argumentos
	VisibleExternalCommands=@(
		'C:\Windows\System32\gpupdate.exe'
	)
	# 3. LA MAGIA: Creamos una función nativa permitida dentro de JEA
    FunctionDefinitions = @(
        @{
            Name = 'Register-MyDNS'
            ScriptBlock = { & C:\Windows\System32\ipconfig.exe /registerdns }
        }
    )
}

'@
    Set-Content -Path $RolePath -Value $RoleContent -Force
}
~~~

>En el ejemplo anterior se integró una función para que permitiera ejecutar un comando únicamente del IPconfig, si agregaba el ipconfig.exe del system32 entonces iba a poder ejecutar el release o renew, pero al crear una función específica se le indicó cuál era el único comando a ejecutar que fue el ipconfig /registerdns

![ArchivosEjemplo](imgs/LaboratorioJEA.zip)


## Crear el archivo de configuración de sesión PSSC
Acá se configura que cuando el usuario se conecte al equipo que tenga esta configuración de JEA se le asigne el rol que se acaba de crear y se ejecuten los comandos bajo una cuenta virtual de administrador.

~~~powershell
Invoke-Command -ComputerName CLI-EQUIPOW1101.miscositas.local -ScriptBlock {
    $ConfigPath = "C:\Program Files\WindowsPowerShell\Modules\LaboratorioJEA\ConfigSoporte.pssc"
    
    $ConfigContent = @'
@{
    SchemaVersion = '2.0.0.0'
    SessionType = 'RestrictedRemoteServer'
    
    # Correr como Administrador Local Virtual
    RunAsVirtualAccount = $true
    
    # Mapear el usuario al rol creado
    RoleDefinitions = @{
        'MISCOSITAS\ftibata' = @{ RoleCapabilities = 'OperadorSoporte' }
    }
}
'@
    Set-Content -Path $ConfigPath -Value $ConfigContent -Force
    
    # Registrar el Endpoint de JEA en el sistema operativo del cliente
    Register-PSSessionConfiguration -Name "SoporteWindowsUpdate" -Path $ConfigPath -Force
}
~~~

## Probar
Se supone que para el que el usuario al cual se le está dando permiso pueda ejecutar los comandos con poderes de admin tendría que conectarse al perfil creado desde el Powershell:

~~~powershell
Enter-PSSession -ComputerName localhost -ConfigurationName SoporteWindowsUpdate
~~~

### Para validar
Se supone que en cosas como Apache que piden o tienen interfaz gráfica con el icono con escudo que indica que si o si tiene que ejecutarse como administrador, se supone que se puede registrar  como servicio para poder aplicar JEA:

~~~powershell
httpd.exe -k install -n "Apache24"
~~~

