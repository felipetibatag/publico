- Crear ***Communication Service***, este es el papá de los servicios internos, uno de ellos será el email communication service.
- Crear ***Email communication service*** 
- En este ***Email communication service*** es donde agrego el dominio, dkim, spf, etc., cuando todo esté en verde entonces voy al ***Communication service*** para conectar este dominio:
![](imgs/Pasted%20image%2020260611234705.png)

![](imgs/Pasted%20image%2020260611234746.png)

- Crear un app por el lado de ***app registrations*** en Entra ID:
![](imgs/Pasted%20image%2020260612001550.png)
- Ahora crear el ***secreto*** en dicha aplicación, el ***secreto*** será el que tengo que configurar en el conector, va a ser la clave para conectarme al servicio.
![](imgs/Pasted%20image%2020260612002237.png)
![](imgs/Pasted%20image%2020260612002722.png)

- En la suscripción que he utilizado en esa toca crear un **Rol Personalizado**, el cual tendrá los permisos para consultar los servicios que tenga la suscripción y se agregarán 2 permisos necesarios para que pueda utilizar el servicio de correo:

![](imgs/Pasted%20image%2020260612004137.png)

![](imgs/Pasted%20image%2020260612004428.png)

- Agregar 2 permisos:

![697](imgs/Pasted%20image%2020260612005135.png)
![](imgs/Pasted%20image%2020260612005206.png)

- Creado el rol, por el mismo lado y en la parte de roles tendría que ver el rol creado y desde ese mismo lado puedo asignar entonces la aplicación para que tenga ese rol con esos permisos:
![](imgs/Pasted%20image%2020260612010420.png)
![697](imgs/Pasted%20image%2020260612010458.png)

En esta pantalla que es donde asigno el rol, se abre debo buscar nuevamente el rol creado lo selecciono, siguiente y busco el aplicativo al cual le voy a asignar el rol. 

![](imgs/Pasted%20image%2020260612011439.png)

También toca asignar un rol ahora en el servicio, anteriormente lo asignamos para que la aplicación tenga acceso en la suscripción ahora toca en el ***Communication Service***, por este lado hago ambas cosas asigno el rol y puedo crear la cuenta con la cual me voy a conectar al servicio, puede ser o una dirección o en este caso un texto.

![](imgs/Pasted%20image%2020260612012524.png)

![](imgs/Pasted%20image%2020260612012700.png)

Ahora para las direcciones autorizadas de envío debe estar registrada acá en **Email Communication Services Domain**, por este mismo lado es que creo las listas de supresión también.

![](imgs/Pasted%20image%2020260612013614.png)

La línea de Powershell de prueba sería esta:

~~~powershell
  

$Password = ConvertTo-SecureString -AsPlainText -Force -String 'secretACA'

$Cred = New-Object -TypeName PSCredential -ArgumentList 'ftuserrelay', $Password

  

Send-MailMessage -From 'DoNotReply@miscomanditos.com' -To 'luisfelipetibatag@gmail.com' -Subject 'Test mail desde Powershell' -Body 'Correo desde Powershell' -SmtpServer 'smtp.azurecomm.net' -Port 587 -Credential $Cred -UseSsl
~~~

![](imgs/Pasted%20image%2020260612014255.png)