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
