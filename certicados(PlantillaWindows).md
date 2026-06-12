# Este al guardarse debe quedar con extensión .inf
~~~ini
[Version]
Signature="$Windows NT$"

[NewRequest]
Subject = "CN=intranet, OU=Tecnologia, O=MisComanidatos S.A, L=Bogota, S=Bogota, C=CO"
KeyLength = 2048
KeySpec = 1
KeyUsage = 0xA0
MachineKeySet = TRUE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
RequestType = PKCS10
FriendlyName = "Certificado_2025_Web_Miscomanditos"

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1 ; Server Authentication

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=intranet.miscomanditos.loc"
~~~
# Esto es para generar el request y después aceptarlo, toca ir al server y traer el cer 😆, a menos que esté para que lo acepte de una:
~~~powershell
certreq -new server-auth.inf server-auth.req
certreq -accept certificado.cer
~~~

Para las plantillas más recientes las que tengan con compatibilidad 2016 en adelante al momento de querer generar el certificado con el req en la página WEB no va a aparecer el template, lo más rápido llevarse el req desde el servidor solicitado a la CA y en la CA ejecutar desde un CMD si o si CMD con un Powershell saca errores:
~~~powershell
certreq -submit -attrib "CertificateTemplate:NombreDeTuPlantilla" solicitud.csr
~~~

Para los casos anteriores para generar el request se puede hacer vía certlm.msc:

![](imgs/Pasted%20image%2020260531211618.png)

Escoger la plantilla que se quiere utilizar:

![](imgs/Pasted%20image%2020260531211739.png)
![](imgs/Pasted%20image%2020260531212248.png)

Campos a llenar:
- Full DN: CN=misitio.miscositas.local
- Common Name: misitio.miscositas.local
- Country: CO
- Locality: Bogota
- Organization: Mis Cositas LTDA
Ahora para la parte de los Alternative Name en la parte "Alternative Name" escoger DNS y agregar todos los que teóricamente serían las posibles direcciones:

![](imgs/Pasted%20image%2020260531212913.png)

![](imgs/Pasted%20image%2020260531213010.png)

![](imgs/Pasted%20image%2020260531213208.png)

Ahora en la CA con el request anterior en un CMD, si o si en un CMD:

~~~powershell
certreq -submit -attrib "CertificateTemplate:NombreDeTuPlantilla" solicitud.csr
~~~

![](imgs/Pasted%20image%2020260531214302.png)

Si no hay problemas deberá generar la salida del certificado a importar después en el servidor que lo solicitó, como lo solicité desde el certlm entonces para importarlo lo importaría desde el certlm, dejarlo en el storage personal:

![](imgs/Pasted%20image%2020260531214627.png)

En el IIS debería verse reflejado y en el certlm debería verse con una llave:

![](imgs/Pasted%20image%2020260531221600.png)

![](imgs/Pasted%20image%2020260531221659.png)