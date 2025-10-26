# Sysprep (W11)
> [!TIP]
> Es mejor realizarlo de esta forma ya que si se instala y se sigue el proceso de siempre de dejar que arranque de forma normal el OS, instalar las cosas y posteriormente intentar sacar el Sysprep va a generar errores con las aplicaciones que se hayan actualizado, de esta forma, con Audit, se inicia, pero con una cuenta que no es admin, una cuenta "especial" para realizar todo lo necesario sin que se ligue nada a nadie.

Se inicia el proceso de instalación normal, se particiona, se deja que pasen los archivos y en el primer reinicio donde ya empieza a pedir el idioma en ese momento se oprime <kbd>CTRL + SHIFT + F3 </kbd>  para activar el modo Audit de *Sysprep*.
  <details>
  <summary>Ver imagen</summary>  
    <img width="1200" height="600" alt="image" src="https://github.com/user-attachments/assets/ed958386-b9ee-4b0f-b3f8-ebbb25c5db59" />
  </details>
  
## Personalización

- Instalar parches y demás cosas, eso si validar que sean de esos ejecutables que al instalar el aplicativo queda en todas las sesiones, con Vscode avisa que el ejecutable por normal que se baja solo sería para un usuario y no para el resto y como la actualización se está realizando con el administrador entonces solo quedaría para él, para ese caso ***VSCode*** ofrece un instalador llamado ***SYSTEM*** con ese queda instalado para todos los usuarios que inicien sesión. 
	
- Con algunos aplicativos puede generar inconvenientes al momento de cerrar el Sysprep, pueden salir mensajes de error como estos:
>[!warning]
>2025-10-25 12:01:16, Error  SYSPRP Package **Microsoft.SecHealthUI_1000.29429.1000.0_x64__8wekyb3d8bbwe** was installed for a user, but not provisioned for all users. This package will not function properly in the sysprep image. 2025-10-25 12:01:16, Error SYSPRP Failed to remove apps for the current user: 0x80073cf2. 

Para este paquete llamado ***Microsoft.SecHealthUI***, se tiene que hacer lo siguiente ya que es un paquete de sistema por defecto:

```Powershell
  Add-AppxProvisionedPackage -Online -PackagePath "C:\Windows\System32\SecurityHealth\10.0.29429.1000-0\Microsoft.SecHealthUI_8wekyb3d8bbwe.appx" -SkipLicense
```

- Con el notepad++ que generaba lo mismo, para no dar tantas vueltas lo que hice fue quitarlo 🤣🤣, pero técnicamente es un bug en los blogs de soporte de Notepad++ indicaban que con versiones anteriores a la última con la que probé funcionanba esa parte sin generar el error en sysprep, para no tener algo desactualizado preferí no instalarlo y ya 🤣.
- Estas son unas personalizaciones recomendables para configurar:

```powershell
# Desactivar efectos visuales
$perfKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $perfKey -Name "VisualFXSetting" -Value 2

# Desactivar transparencias y animaciones
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))

#quitar animaciones de fade al abrir/cerrar ventanas.
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0

#para validar que el anterior ajuste de anti-fade funcionó
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

```

Una vez se tenga lo anterior entonces se procede con el cierre de Sysprep, para este ejemplo se uso un archivo de configuración desantendida que se encargue de crear el usuario que iniciará sesión entre otras cosas, el archivo de configuración realiza lo siguiente:

1. Configura las preferencias de idioma.
2. Crea un usuario y lo ubica en el grupo de administrador y le fja una clave.
3. Deja el usuario administrador desactivado.

[unnatend.xml](https://github.com/felipetibatag/publico/blob/main/unattend.xml)

Dicho archivo ***unnatend.xml***  debe ser utilizado al momento de generar el Sysprep de la siguiente forma:

```powershell
sysprep.exe /audit /generalize /shutdown /unattend:C:\temp\unattend.xml /mode:vm
```

Con lo anterior cierra el Sysprep y queda lista la imagen para ser clonada, al momento que se prenda se verían las siguientes ventanas y la bievenida de siempre, pero sin pedir datos adicionales ya que el usuario ya va creado:

<img width="1473" height="934" alt="image" src="https://github.com/user-attachments/assets/48d6177a-3226-48bb-b792-27754757d584" />

<img width="1444" height="915" alt="image" src="https://github.com/user-attachments/assets/41319c4d-348b-4185-bfcd-547cc43d0b5a" />


