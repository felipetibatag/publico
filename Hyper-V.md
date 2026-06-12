
### Fase 1: Preparación del Entorno

~~~powershell
# 1. Configurar rutas globales
$DefaultVirtualDiskPath = "D:\Hyper-V\Disks"
$DefaultVMPath = "D:\Hyper-V\VMs"
New-Item -ItemType Directory -Force -Path $DefaultVirtualDiskPath, $DefaultVMPath
Set-VMHost -VirtualHardDiskPath $DefaultVirtualDiskPath -VirtualMachinePath $DefaultVMPath

# 2. Crear Switches de Red
New-VMSwitch -Name "Switch-Externo-Internet" -NetAdapterName "Ethernet" -AllowManagementOS $true
New-VMSwitch -Name "Switch-Laboratorio-Interno" -SwitchType Internal
~~~

### Fase 2: Creación de Plantillas (Master Images)

~~~powershell
# --- MAESTRA WINDOWS SERVER 2022 ---
$VMName = "SRV-MAESTRO-2022"
$VHDPath = "$DefaultVirtualDiskPath\$VMName.vhdx"
New-VHD -Path $VHDPath -SizeBytes 60GB -Dynamic
New-VM -Name $VMName -MemoryStartupBytes 4GB -Generation 2 -Path $DefaultVMPath -VHDPath $VHDPath -SwitchName "Switch-Externo-Internet"
Set-VMProcessor -VMName $VMName -Count 4
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 4GB -MaximumBytes 8GB
Set-VMDvdDrive -VMName $VMName -Path "E:\ISO\WindowsServer2022.iso"

# [PAUSA: Instalar Windows y realizar Sysprep en la VM]
# C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown
# Despues de sysprep, marcar como solo lectura:
Set-ItemProperty -Path $VHDPath -Name IsReadOnly -Value $true

# --- MAESTRA WINDOWS 11 ---
$VMNameW11 = "W11-MAESTRO"
$VHDPathW11 = "$DefaultVirtualDiskPath\$VMNameW11.vhdx"
New-VHD -Path $VHDPathW11 -SizeBytes 80GB -Dynamic
New-VM -Name $VMNameW11 -MemoryStartupBytes 4GB -Generation 2 -Path $DefaultVMPath -VHDPath $VHDPathW11 -SwitchName "Default Switch"
Set-VMProcessor -VMName $VMNameW11 -Count 4
Set-VMMemory -VMName $VMNameW11 -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 4GB -MaximumBytes 12GB
Add-VMDvdDrive -VMName $VMNameW11 -Path "E:\ISO\W11.iso"
Set-VMKeyProtector -VMName $VMNameW11 -NewLocalKeyProtector
Set-VMSecurity -VMName $VMNameW11 -TpmEnabled $true -UntrustedComponentsState $true
# [PAUSA: Instalar Windows y aplicar Sysprep]
Set-ItemProperty -Path $VHDPathW11 -Name IsReadOnly -Value $true
~~~
### Fase 3: Despliegue de Infraestructura (Servidores)
~~~powershell
# 1. Crear VM desde la maestra
$DefaultVirtualDiskPath = "D:\Hyper-V\Disks"
$DefaultVMPath = "D:\Hyper-V\VMs"
$NewVMName = "DC01"
$ChildPath = "$DefaultVirtualDiskPath\$NewVMName.vhdx"
New-VHD -ParentPath "$DefaultVirtualDiskPath\SRV-MAESTRO-2022.vhdx" -Path $ChildPath -Differencing
New-VM -Name $NewVMName -MemoryStartupBytes 4GB -Generation 2 -Path $DefaultVMPath -VHDPath $ChildPath -SwitchName "Switch-Laboratorio-Interno"

# 2. Configurar Red y Dominio (Dentro del servidor DC01)
Rename-Computer -NewName "DC01" -Force
$NetAdapter = Get-NetAdapter | Where-object Status -Eq "Up"
New-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex -IPAddress "192.168.10.10" -PrefixLength 24 -DefaultGateway "192.168.10.1"
Set-DnsClientServerAddress -InterfaceIndex $NetAdapter.InterfaceIndex -ServerAddresses "127.0.0.1"
Restart-Computer -Force

# 3. Instalar Roles (AD + DHCP)
Install-WindowsFeature -Name AD-Domain-Services, DHCP -IncludeManagementTools
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "WinThreshold" -DomainName "miscositas.local" -ForestMode "WinThreshold" -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -Force:$true

# 4. Configurar DHCP
Add-DhcpServerInDC -DnsName "DC01.miscositas.local" -IPAddress 192.168.10.10
Add-DhcpServerv4Scope -Name "Red-Laboratorio-Interno" -StartRange 192.168.10.50 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 3 -Value "192.168.10.1"
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 6 -Value "192.168.10.10"
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 15 -Value "miscositas.local"
Add-DhcpServerSecurityGroup
Restart-Service -Name DHCPServer -Force
~~~
### Fase 4: Despliegue de Clientes
~~~powershell
$DefaultVirtualDiskPath = "D:\Hyper-V\Disks"
$ClientName = "CLI-W11-01"
$ChildPath = "$DefaultVirtualDiskPath\$ClientName.vhdx"
New-VHD -ParentPath "$DefaultVirtualDiskPath\W11-MAESTRO.vhdx" -Path $ChildPath -Differencing
New-VM -Name $ClientName -MemoryStartupBytes 4GB -Generation 2 -Path $DefaultVMPath -VHDPath $ChildPath -SwitchName "Switch-Laboratorio-Interno"

# Configuración de seguridad específica para Windows 11
Set-VMKeyProtector -VMName $ClientName -NewLocalKeyProtector
Set-VMFirmware -VMName $ClientName -EnableSecureBoot Off

# Unión al dominio (Ejecutar tras configurar red en el cliente)
Add-Computer -DomainName "miscositas.local" -Restart
~~~
