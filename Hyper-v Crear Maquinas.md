
~~~powershell
# Si tiene alguna dependencia de la tienda entonces no va a servir el sysprep
Get-AppxPackage | Where-Object {$_.NonRemovable -eq $false} | Remove-AppxPackage
# Toca con esta linea indicandole que el sysprep es desde una VM
sysprep.exe /oobe /generalize /shutdown /mode:vm
~~~
~~~powershell
write-host "Creando Variables" -ForegroundColor green
$vmName = "fileserver"
$rootPath="D:\HyperVMS"
$VmPathNewDisco="Discos\$vmName.vhdx"
$pathBase="E:\basesDiscos\W2022"
$nombreDiscoBase="W2022.vhdx"
$vhdPathBaseDisco = "$pathBase\$nombreDiscoBase"
$switchName = "LAN_Miscomanditos"

#CreandoDirectorios
write-host "Creando directorio para la VM - $vmName" -ForegroundColor green
New-Item -type Directory -Path "$rootPath\VMs\$vmName"|out-null
write-host "Creando directorio para el disco $vmName" -ForegroundColor green
New-Item -type Directory -Path "$rootPath\Discos\$vmName"|out-null
#Disco
write-host "Copiando $nombreDiscoBase"  -ForegroundColor green
Robocopy $pathBase "$rootPath\Discos\$vmName" $nombreDiscoBase /NJS /NJH
write-host "Renombrando $nombreDiscoBase a $vmName.vhdx"  -ForegroundColor green
Rename-Item "$rootPath\Discos\$vmName\$nombreDiscoBase" "$vmName.vhdx"
#Maquina
write-host "Modificando caracteristicas VM - $vmName"
New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 2 -Path "$rootPath\VMs\$vmName" -SwitchName $switchName |out-null
Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "$rootPath\Discos\$vmName\$vmName.vhdx"
Set-VMFirmware -VMName $vmName -EnableSecureBoot On
Set-VMProcessor -VMName $vmName -Count 4
Set-VM -Name $vmName -CheckpointType Disabled
Set-VMFirmware -VMName $vmName -FirstBootDevice (Get-VMHardDiskDrive -VMName $vmName)
write-host "Iniciando  VM $vmName"
Start-VM -Name $vmName
~~~
