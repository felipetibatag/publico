# Procedimiento Estándar Operativo (SOP): Migración y Eliminación de Base de Datos en Exchange 2016 (Entorno DAG)

**Objetivo:** Migrar buzones activos, monitorear el whitespace y eliminar de forma segura una base de datos obsoleta en un clúster DAG (Database Availability Group) de 3 nodos, sin dejar residuos en Active Directory.

---

## FASE 1: Preparación del Entorno (Creación)

~~~powershell
# Crear la base de datos destino con sus rutas (Cambia TU_SERVIDOR_ACTIVO por el nombre explícito de tu servidor)
New-MailboxDatabase -Name "DB-TEST-02" -Server TU_SERVIDOR_ACTIVO -EdbFilePath "C:\ExchangeDatabases\DB-TEST-02\DB-TEST-02.edb" -LogFolderPath "C:\ExchangeDatabases\DB-TEST-02\Logs"

# Montar la base de datos para habilitar su uso
Mount-Database -Identity "DB-TEST-02" 

# (OPCIONAL PERO RECOMENDADO EN DAG): Agregar copias de la nueva BD a los otros 2 nodos
Add-MailboxDatabaseCopy -Identity "DB-TEST-02" -MailboxServer NODO_DAG_2 -ActivationPreference 2
Add-MailboxDatabaseCopy -Identity "DB-TEST-02" -MailboxServer NODO_DAG_3 -ActivationPreference 3
~~~

## FASE 2: Diagnóstico y Migración

~~~powershell
# Medir el Whitespace Inicial
Get-MailboxDatabase -Status | Select-Object Name, DatabaseSize, AvailableNewMailboxSpace

# Lanzar el lote de migración de la DB original a la nueva
Get-Mailbox -Database "Mailbox Database 0588585608" | New-MoveRequest -TargetDatabase "DB-TEST-02" -BatchName "MigracionLabWhitespace"

# Monitorear el progreso del movimiento:
Get-MoveRequest -BatchName "MigracionLabWhitespace" | Get-MoveRequestStatistics
~~~

## FASE 3: Limpiar los registros de MoveRequest

~~~powershell
# Limpiar SOLAMENTE las completadas para no afectar migraciones en curso
Get-MoveRequest | Where-Object Status -eq "Completed" | Remove-MoveRequest -Confirm:$false
~~~

## FASE 4: Eliminación segura de la Base de Datos (Saneamiento)

~~~powershell
# Paso 1: Verificar que no queden buzones normales
Get-Mailbox -Database "Mailbox Database 0588585608"

# Paso 2: Forzar el movimiento de cualquier buzón oculto del sistema a la nueva BD
Get-Mailbox -Database "Mailbox Database 0588585608" -Arbitration | New-MoveRequest -TargetDatabase "DB-TEST-02"
Get-Mailbox -Database "Mailbox Database 0588585608" -Monitoring | New-MoveRequest -TargetDatabase "DB-TEST-02"
Get-Mailbox -Database "Mailbox Database 0588585608" -AuditLog | New-MoveRequest -TargetDatabase "DB-TEST-02"

# Paso 3: Esperar a que terminen y eliminar estas nuevas solicitudes de sistema
Get-MoveRequest | Where-Object Status -eq "Completed" | Remove-MoveRequest -Confirm:$false
~~~

## FASE 5: Desmantelamiento en entorno DAG (Eliminación de Réplicas)

~~~powershell
# Paso 4: Eliminar las copias pasivas en los otros dos servidores ANTES de borrar la activa
Remove-MailboxDatabaseCopy -Identity "Mailbox Database 0588585608\NOMBRE_NODO_2" -Confirm:$false
Remove-MailboxDatabaseCopy -Identity "Mailbox Database 0588585608\NOMBRE_NODO_3" -Confirm:$false

# Paso 5: Desmontar y eliminar la base de datos de Active Directory
Dismount-Database -Identity "Mailbox Database 0588585608" -Confirm:$false
Remove-MailboxDatabase -Identity "Mailbox Database 0588585608" -Confirm:$false
~~~

> **Warning:** Al ejecutar el último comando, Exchange arrojará una advertencia indicando que el archivo físico no ha sido eliminado. Esto es el comportamiento esperado.

-------

## FASE 6: Limpieza Física (Recuperación de Almacenamiento)

Como último paso, es necesario recuperar los gigabytes de almacenamiento a nivel del sistema operativo Windows Server en **los 3 servidores del clúster DAG**.

1. Ingresa a cada uno de los 3 nodos Mailbox (vía RDP o acceso por red).
2. Navega a la ruta de instalación: `C:\Program Files\Microsoft\Exchange Server\V15\Mailbox\`
3. Elimina manualmente la carpeta `Mailbox Database 0588585608` completa en cada nodo.