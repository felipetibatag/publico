# Configuración y Validación de Relaciones de Confianza entre Dominios

Este documento resume los pasos realizados para establecer una relación de confianza entre los dominios `miscomanditos.loc` y `dominio2.loc`, incluyendo comandos recomendados para validación antes y después de la configuración.

---

## 1. Información de los dominios involucrados

| Hostname | Dominio              | Rol         |
|----------|----------------------|-------------|
| dc       | miscomanditos.loc    | Forest Root |
| dcpy     | dominio2.loc         | Forest Root |

Ambos dominios tienen usuarios llamados `usertrust` con privilegios de `Enterprise Admins`.

---

## 2. Configuración de la relación de confianza

- Se utilizó el asistente de confianza en `Active Directory Domains and Trusts`.
- Se seleccionó la opción: `"Both this domain and the specified domain"`.
- Se ingresó el nombre del dominio remoto usando su nombre DNS:
  - Desde `miscomanditos.loc`: `dominio2.loc`
  - Desde `dominio2.loc`: `miscomanditos.loc`
- Se ingresaron credenciales en formato:
  - `DOMINIO2\usertrust` o `usertrust@dominio2.loc`
  - `MISCOMANDITOS\usertrust` o `usertrust@miscomanditos.loc`
- Se seleccionó el nivel de autenticación: `Forest-wide authentication`.

---

## 3. Validaciones previas a la configuración

### 3.1. Resolución DNS

```powershell
nslookup dominio2.loc
nslookup miscomanditos.loc
```
### 3.2. Conectividad entre controladores de dominio
```powershell
  Test-Connection dc.dominio2.loc
  Test-Connection dcpy.miscomanditos.loc
```

### 3.3. Sincronización horaria (Kerberos)
```powershell
w32tm /stripchart /computer:dc.dominio2.loc /samples:5 /dataonly
w32tm /stripchart /computer:dc.miscomanditos.loc /samples:5 /dataonly
```
### 3.4. Verificación de puertos abiertos (netstat
```powershell
netstat -an | findstr :135
netstat -an | findstr :389
netstat -an | findstr :445
netstat -an | findstr :88
netstat -an | findstr :636
```
## 4. Validaciones posteriores a la configuración
### 4.1. Verificar relaciones de confianza activa
```powershell
nltest /trusted_domains
```
### 4.2. Probar autenticación cruzada
```powershell
nltest /server:dc /sc_query:dominio2.loc
nltest /server:dcpy /sc_query:miscomanditos.loc
```
