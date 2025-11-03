>[!important]
>Todos los certificados que usa el sitio deben estar en PEM.


# Instalación

~~~bash
# Instalar Apache2
sudo apt install apache2 -y

# Ver la versión instalada
apache2 -v

# Ver el estado del servicio
sudo systemctl status apache2

# Si no está corriendo, inícialo
sudo systemctl start apache2

# Habilitarlo para que inicie automáticamente
sudo systemctl enable apache2
~~~

# Probar Apache
~~~bash
curl http://localhost
~~~

# Directorios Apache
> - /var/www/html/              # Sitio por defecto (como el "www" de antes)
> - /etc/apache2/               # Configuración principal
> - /etc/apache2/sites-available/   # Configuraciones de sitios (inactivos)
> - /etc/apache2/sites-enabled/     # Sitios activos (symlinks)

# Habilitar módulo SSL en Apache
Esto los que permite se agregue un certificado SSL.
~~~bash
sudo a2enmod ssl
sudo systemctl restart apache2
~~~

# Crear Virtual Host
Para la práctica se hizo con un sitio llamado **sitiolinux**.
~~~bash
sudo mkdir -p /var/www/sitiolinux/public_html
sudo chown -R $USER:$USER /var/www/sitiolinux/public_html
sudo chmod -R 755 /var/www/sitiolinux
~~~

# Crear la página de test
~~~bash
nano /var/www/sitiolinux/public_html/index.html
#agregar cualquier cosa en el index...es la página de test..
~~~

# Creacion request certificado
La idea es:
- Crear el directorio **ssl** en la ruta **/etc/apache2/**. En dicho directorio voy a dejar los certificados en formato PEM de:
  - Ceritificado CA root.
  - Llave generada ya que en Linux toca generar la llave.
  - Certificado del sitio generado. Acá puedo puedo dejar inicialmente el CSR (request) que me va a servir para crear este certificado del sitio.
  - Acá también puedo dejar el archivo [san.cnf](https://github.com/felipetibatag/publico/blob/main/certificados(plantillaLinux).cnf), modificado...ajustado al sitio.

~~~bash
# Crear directorio para los certificados
sudo mkdir -p /etc/apache2/ssl
# Crear 🔑LLAVE y el 📜REQUEST
# el cual utilizará una CONFIGURACIÓN san.cnf que tiene todos los datos, es la plantilla.
sudo openssl req -new -newkey rsa:2048 -nodes -keyout sitiolinux.key -out requestsitiolinux.csr -config san.cnf
~~~

Con lo anterior no me ve a pedir datos ya que ya están en la plantilla

<img width="1431" height="210" alt="image" src="https://github.com/user-attachments/assets/d77720dd-e5f5-44e5-b027-5a30a07d5ada" />

Estos serían los archivos que debería ver:

<img width="511" height="132" alt="image" src="https://github.com/user-attachments/assets/877bad00-db22-4652-a128-e3b110434ecf" />

Con el request hago lo mismo de siempre lo habro lo copio y lo pongo en la CA para que me de el certificado el cual debo exportarlo em **PEM**.

# Crear archivo de configuración del Virtual Host

~~~bash
sudo nano /etc/apache2/sites-available/sitiolinux.conf
~~~

Tendrá el siguiente contenido, la parte del puerto 80 es la redirección:

~~~bash
<VirtualHost *:443>
        ServerName sitiolinux
        ServerAlias www.sitiolinux.loc
        ServerAdmin admin@sitiolinux.loc
        DocumentRoot /var/www/sitiolinux/public_html

        SSLEngine on
        SSLCertificateFile /etc/apache2/ssl/sitiolinux.cer
        SSLCertificateKeyFile /etc/apache2/ssl/sitiolinux.key
        SSLCertificateChainFile /etc/apache2/ssl/rootCA.cer

        <Directory /var/www/sitiolinux/public_html>
                Options Indexes FollowSymLinks
                AllowOverride All
                Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/sitiolinux-error.log
        CustomLog ${APACHE_LOG_DIR}/sitiolinux-access.log combined
</VirtualHost>

<VirtualHost *:80>
        ServerName sitiolinux
        ServerAlias www.sitiolinux.loc

        Redirect permanent / https://sitiolinux/
</Virtualhost>
~~~

# Habilitar sitio
~~~bash
# Habilitar el nuevo sitio
sudo a2ensite sitiolinux.conf

# Verificar la configuración
sudo apache2ctl configtest

# Recargar Apache
sudo systemctl reload apache2
~~~

<img width="833" height="709" alt="image" src="https://github.com/user-attachments/assets/d509e361-f54e-448c-848e-ad383c278046" />
