~~~powershell
$miId  = "<ObjectId de ctaautomatizacion1>"
$graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" # este es el app id de la cual voy a dar permiso, de la que se supone tiene el rol a asignar.

## ver que roles existen para escoger cuál voy a asignar a la cuenta miID, que es la identidad de la cuenta de automatización.

$graph.AppRoles | ? { $_.Value -like "User.Read*" } | select Value, Id

#Detectado el rol que requiero ...pues lo asigno

$role = $graph.AppRoles | ? { $_.Value -eq "User.Read.All" -and $_.AllowedMemberTypes -contains "Application" }

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId -PrincipalId $miId -ResourceId $graph.Id -AppRoleId $role.Id
~~~

El `$miID` lo saco de acá:

![](imgs/Pasted%20image%2020261121154025.png)

En la aplicación empresarial de Graph se verá replicado el permiso, toca esperar unos 2 minutos para que la cuenta de automatización tenga bien los permisos:

![](imgs/Pasted%20image%2020261107200835.png)

# Guía rápida: reporte de cuarentena con Azure Automation

Nov 21, 2026 · @Felipe

## 1. La receta (5 piezas)

Un runbook se conecta a Exchange Online con una identidad administrada, lista la cuarentena, arma un CSV y lo envía por correo. Si falta una de estas 5 piezas, falla:

1. **Runtime PowerShell 7.4** (EXO 3.6+ no corre en 7.2 por .NET 8).
2. **Módulo `ExchangeOnlineManagement`** agregado desde la galería al entorno 7.4.
3. **App role `Exchange.ManageAsApp`** asignado a la identidad (sirve para entrar).
4. **Rol de Entra "Lector de seguridad"** asignado a la identidad (define qué puede leer).
5. **Dominio `<tenant>.onmicrosoft.com`** en `-Organization` (no el dominio personalizado).

El envío usa `Mail.Send` de Graph, que ya debe estar asignado a la identidad.

*Dónde ver el dominio `.onmicrosoft.com`:* **Entra ID → Nombres de dominio personalizados**. Es el que no tiene la marca de "Principal" y dice *Disponible*.

## 2. Configuración (una sola vez)

**A. Identidad.** Cuenta de Automation → Configuración → Identidad → Asignado por el sistema → Activado. Copia el *Id. de objeto*.

*Dónde:* menú izquierdo de la cuenta → **Configuración de la cuenta → Identidad** → pestaña **Asignado por el sistema**. El Id. de objeto aparece debajo del interruptor, con botón de copiar.

**B. Entorno de ejecución.** Entornos de ejecución → Crear → PowerShell **7.4**. Agrega desde la galería `ExchangeOnlineManagement` y `Microsoft.Graph.Authentication` (2.x). Espera a que ambos digan *Disponible*.

*Dónde:* menú izquierdo de la cuenta → **Automatización de procesos → Entornos de ejecución**. Dentro del entorno: **Agregar desde la galería**.

**C. Permisos en tu PC** (PowerShell 7, módulos `Microsoft.Graph.Authentication` y `Microsoft.Graph.Applications`):

```powershell
Connect-MgGraph -Scopes Application.ReadWrite.All,AppRoleAssignment.ReadWrite.All
$miId = "<Id de objeto>"   # Portal Azure > Cuenta de Automation > Configuración de la cuenta > Identidad > Asignado por el sistema > "Id. de objeto (entidad de seguridad)" (botón copiar)

# Exchange.ManageAsApp
$exo  = Get-MgServicePrincipal -Filter "appId eq '00000002-0000-0ff1-ce00-000000000000'"
$role = $exo.AppRoles | ? { $_.Value -eq "Exchange.ManageAsApp" }
$role | Select Value, Id      # confirma que NO está vacío
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId -PrincipalId $miId -ResourceId $exo.Id -AppRoleId $role.Id

# Mail.Send (para el envío por Graph)
$graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$role  = $graph.AppRoles | ? { $_.Value -eq "Mail.Send" -and $_.AllowedMemberTypes -contains "Application" }
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId -PrincipalId $miId -ResourceId $graph.Id -AppRoleId $role.Id
```

Verifica que quedaron: `Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId | Select ResourceDisplayName, AppRoleId` debe listar *Office 365 Exchange Online* y *Microsoft Graph*.

*Dónde ver los permisos en el portal:* **Entra ID → Aplicaciones empresariales** (quita el filtro "Aplicaciones de Microsoft") → busca el nombre de la cuenta → **Permisos**. Deben salir 4 filas: tres de Microsoft Graph y `Exchange.ManageAsApp`.

**D. Rol de Entra.** Entra ID → Roles y administradores → **Lector de seguridad** → Agregar asignaciones → la identidad, asignación **Activa**.

*Dónde:* **Entra ID → Roles y administradores** → busca "seguridad" → clic en el nombre **Lector de seguridad** (no solo la casilla) → **Asignaciones → Agregar asignaciones**. Si no encuentra la identidad por nombre, pega su Id. de objeto.

**E. Variables.** Recursos compartidos → Variables → dos String: `Reporte_Remitente` y `Reporte_Destinatario`.

*Dónde:* menú izquierdo de la cuenta → **Recursos compartidos → Variables → Agregar una variable**.

Espera 5 a 10 minutos para que los permisos se propaguen.

## 3. El runbook

Crea `Reporte-Cuarentena` (PowerShell, entorno 7.4) y pega este código. Cambia solo el dominio `.onmicrosoft.com`.

```powershell
# Variables de la cuenta
$remitente    = Get-AutomationVariable -Name 'Reporte_Remitente'
$destinatario = Get-AutomationVariable -Name 'Reporte_Destinatario'

# 1. Consultar cuarentena (EXO) y cerrar sesión antes de usar Graph
Connect-ExchangeOnline -ManagedIdentity -Organization "<tenant>.onmicrosoft.com" -ShowBanner:$false
$q = Get-QuarantineMessage -StartReceivedDate (Get-Date).AddDays(-7) -PageSize 100
Disconnect-ExchangeOnline -Confirm:$false
Write-Output "Mensajes en cuarentena (7 días): $($q.Count)"

# 2. Armar el reporte (listas -> texto con -join)
$rep = [System.Collections.Generic.List[object]]::new()
foreach ($m in $q) {
    $rep.Add([pscustomobject]@{
        ReceivedTime     = $m.ReceivedTime
        SenderAddress    = $m.SenderAddress
        RecipientAddress = ($m.RecipientAddress -join ';')
        Subject          = $m.Subject
        QuarantineTypes  = ($m.QuarantineTypes -join ';')
    })
}

# 3. CSV en la carpeta temporal del sandbox
$csv = Join-Path $env:TEMP "mensajesCuarentena_$(Get-Date -Format yyyyMMdd).csv"
$rep | Export-Csv $csv -NoTypeInformation -Encoding UTF8

# 4. Enviar por Graph (REST)
Connect-MgGraph -Identity -NoWelcome
$bytes = [IO.File]::ReadAllBytes($csv)
$msg = @{
  Message = @{
    Subject      = "Mensajes en cuarentena $(Get-Date -Format yyyy-MM-dd)"
    Body         = @{ ContentType = "Text"; Content = "Adjunto reporte. Mensajes en cuarentena: $($rep.Count)" }
    ToRecipients = @(@{ EmailAddress = @{ Address = $destinatario } })
    Attachments  = @(@{
      "@odata.type" = "#microsoft.graph.fileAttachment"
      Name          = Split-Path $csv -Leaf
      ContentBytes  = [Convert]::ToBase64String($bytes)
    })
  }
  SaveToSentItems = $false
}
Invoke-MgGraphRequest -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/users/$remitente/sendMail" `
  -Body ($msg | ConvertTo-Json -Depth 10) `
  -ContentType "application/json"
```

Prueba en el **Panel de prueba**; cuando llegue el correo, **Guardar → Publicar**.

## 4. Programarlo

1. Runbook publicado → **Recursos → Programas → Agregar un programa → Crear un nuevo programa**.
2. Zona horaria **America/Bogota** (si no, corre en UTC, 5 horas desfasado).
3. Periodicidad **Periódico → 1 día**, sin expiración. La hora de inicio debe ser futura.
4. Revisa el resultado en **Trabajos** del runbook. Un job programado puede tardar unos minutos en arrancar.

## 5. Si falla: qué capa revisar

| Error | Causa | Solución |
| --- | --- | --- |
| `Unable to find type ... System.Runtime 8.0.0.0` | Runtime 7.2 con EXO 3.6+ | Usar entorno PowerShell 7.4 |
| `Connect-ExchangeOnline` no reconocido | Módulo mal importado o en otro entorno | Reimportar desde la galería; revisar que el runbook use el entorno correcto |
| `UnAuthorized` al conectar | Falta `Exchange.ManageAsApp` o `-Organization` incorrecto | Verificar con `Get-MgServicePrincipalAppRoleAssignment`; usar el dominio `.onmicrosoft.com` |
| `Get-QuarantineMessage` no reconocido tras conectar | Falta el rol de Entra | Asignar Lector de seguridad (activo) y esperar la propagación |
| `Insufficient privileges` en Graph | Falta el permiso de aplicación | Asignar el app role y esperar 2 a 3 minutos |
| `Connect-MgGraph` / `Invoke-MgGraphRequest` no reconocidos | Falta `Microsoft.Graph.Authentication` en el entorno 7.4 | Agregarlo desde la galería |
| Panel de prueba muestra la salida vieja | Se usó "Ver la última prueba" | Presionar **Inicio** de nuevo |

Prueba GTUBE para generar un mensaje de cuarentena en un tenant de pruebas: enviar a un buzón del tenant, con el cuerpo solo con `XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X`.
