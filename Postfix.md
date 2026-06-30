### Tabla de Comandos Útiles - Postfix & Azure ACS

|**Categoría**|**Comando**|**Descripción / Uso**|
|---|---|---|
|**Bases de Datos & Mapas**|`sudo postmap lmdb:/etc/postfix/sasl_passwd`|Compila e indexa las credenciales en formato moderno **LMDB**.|
|**Bases de Datos & Mapas**|`postmap -q "[smtp.azurecomm.net]:587" lmdb:/etc/postfix/sasl_passwd`|Interroga la base de datos para verificar qué credencial exacta lee Postfix.|
|**Gestión del Servicio**|`sudo systemctl restart postfix`|Reinicia por completo el demonio de Postfix para cargar cambios en memoria.|
|**Gestión de la Cola**|`mailq` _(o `postqueue -p`)_|Muestra el listado de correos retenidos en la cola y la causa exacta del retraso.|
|**Gestión de la Cola**|`sudo postfix flush`|Fuerza a Postfix a procesar e intentar enviar inmediatamente todo lo encolado.|
|**Gestión de la Cola**|`sudo postsuper -d ALL`|Borra de forma radical **absolutamente todos** los correos alojados en la cola local.|
|**Pruebas de Envío**|`echo "Cuerpo" \| mailx -s "Asunto" -r "remitente@dominio.com" destino@correo.com`|Envía un correo de prueba estándar a través del relay de forma lineal.|
|**Pruebas de Envío**|`echo "Cuerpo" \| mailx -v -s "Asunto" -r "remitente@dominio.com" destino@correo.com`|Envía un correo activando el modo detallado (_verbose_) en la terminal.|
|**Monitoreo & Logs**|`sudo journalctl -u postfix -f`|Monitorea en tiempo real (_follow_) los sucesos y negociaciones SMTP de Postfix.|
|**Limpieza de Logs**|`sudo journalctl --rotate`|Fuerza la rotación de los archivos de registro actuales, archivando lo viejo.|
|**Limpieza de Logs**|`sudo journalctl --vacuum-time=1s`|Poda y vacía el caché del journal de forma inmediata a cero.|
|**Limpieza de Logs**|`sudo journalctl --vacuum-size=100M`|Reduce el tamaño de los logs conservando únicamente los últimos 100 Megabytes.|
|**Firewall del Sistema**|`sudo firewall-cmd --permanent --add-service=smtp`|Abre el puerto `25` de manera permanente en el firewall de openSUSE.|
|**Firewall del Sistema**|`sudo firewall-cmd --reload`|Recarga las reglas del firewall para aplicar la apertura de puertos.|

### 📌 Recordatorio de las rutas clave utilizadas:

- **Configuración principal:** `/etc/postfix/main.cf`
    
- **Configuración de procesos maestros:** `/etc/postfix/master.cf`
    
- **Archivo de credenciales:** `/etc/postfix/sasl_passwd`
    
- **Configuración del Journal:** `/etc/etc/systemd/journald.conf`