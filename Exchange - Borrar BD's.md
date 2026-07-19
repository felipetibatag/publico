
# Medir el Whitespace Inicial
~~~powershell
Get-MailboxDatabase -Status | Select-Object Name, DatabaseSize, AvailableNewMailboxSpace
~~~
# Practicar la Migración (Mover cuentas para liberar espacio)
## Lanzar el lote de migración de la DB1 a la DB2
~~~powershell
Get-Mailbox -Database "Mailbox Database 0588585608" | New-MoveRequest -TargetDatabase "DB-TEST-02" -BatchName "MigracionLabWhitespace"
~~~
# Monitorear el progreso del movimiento:
~~~powershell
Get-MoveRequest -BatchName "MigracionLabWhitespace" | Get-MoveRequestStatistics
~~~
## Parte 1: Limpiar los registros de MoveRequest completados
~~~powershell
Get-MoveRequest|Where-Object status -eq "Completed"|Remove-MoveRequest -Confirm:$false
~~~
# Parte 2: Eliminación segura de la Base de Datos (Sin residuos en AD)
* Paso 1: Verificar que no queden buzones ocultos o del sistema
1. Buzones normales de usuario (Ya debería estar vació tras tu migración)
~~~powershell
Get-Mailbox -Database "Mailbox Database 0588585608"
~~~
2. Buzones de Arbitraje (System Mailboxes)
~~~powershell
Get-Mailbox -Database "Mailbox Database 0588585608" -Arbitration| New-MoveRequest -TargetDatabase "DB-TEST-02"
~~~
3. Buzones de Monitoreo (Health Mailboxes)
~~~powershell
Get-Mailbox -Database "Mailbox Database 0588585608" -Monitoring| New-MoveRequest -TargetDatabase "DB-TEST-02"
~~~
4. Buzones de Auditoría (Audit Log Mailboxes)
~~~powershell
Get-Mailbox -Database "Mailbox Database 0588585608" -AuditLog| New-MoveRequest -TargetDatabase "DB-TEST-02"
~~~
# SI FUE NECESARIO MOVER LOS BUZONES DE Arbitration,Monitoring, AuditLog ENTONCES también toca eliminar esas solicitudes de movimiento.
~~~powershell
Get-MoveRequest|Remove-MoveRequest -Confirm:$false
~~~
# ELIMINAR AHORA SI LA BD
~~~powershell
remove-MailboxDatabase -Identity "Mailbox Database 0588585608" -Confirm:$false
~~~

>WARNING: The specified database has been removed. You must remove the database file located in 
>C:\Program Files\Microsoft\Exchange Server\V15\Mailbox\Mailbox Database 0588585608\Mailbox Database 0588585608.edb from your
>computer manually if it exists. Specified database: Mailbox Database 0588585608


