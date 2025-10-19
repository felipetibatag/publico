#!/bin/bash

# 🎨 Colores
crojo()  { echo -e "\e[31m$1\e[0m"; }
cverde() { echo -e "\e[32m$1\e[0m"; }
cmage()  { echo -e "\e[35m$1\e[0m"; }

# 🧾 Función para imprimir clave/valor
cinfo() {
  local etiqueta="$1"
  local valor="$2"
  printf "%-25s : %s\n" "$(cmage "$etiqueta")" "$valor"
}

# 📦 Hostname
nombreServidor=$(hostname)
cinfo "Hostname" "$nombreServidor"

# 🌐 IP v4
ipv4=$(ip -4 -o a | awk '$2 != "lo" {print $4; exit}')
cinfo "IPv4" "$ipv4"

# 🌐 IP v6 activo
ipv6=$(ip -6 a | grep -v 'lo' | grep inet6)
if [ -n "$ipv6" ]; then
  cinfo "IPv6" "$(crojo "Activo")"
else
  cinfo "IPv6" "$(cverde "No activo")"
fi

# 🚪 Puerta de enlace
gateway=$(ip route | grep default | awk '{print $3}')
cinfo "Gateway" "$gateway"

# 🧭 DNS
dns=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | paste -sd ", ")
cinfo "DNS" "$dns"

# 🔥 Firewall activo
if systemctl is-active --quiet firewalld || systemctl is-active --quiet ufw; then
  cinfo "Firewall" "$(cverde "Activo")"
else
  cinfo "Firewall" "$(crojo "No activo")"
fi

# 💽 Particiones y tipo
echo "$(cmage "Particiones y tipo de formato")"
lsblk -o NAME,FSTYPE,TYPE | grep part | while read -r name fstype type; do
  if [[ "$fstype" == "lvm" || "$fstype" == "LVM2_member" ]]; then
    printf "%-10s %-15s\n" "$name" "$(cverde "$fstype")"
  else
    printf "%-10s %-15s\n" "$name" "$(crojo "$fstype")"
  fi
done

# 🔐 Directiva de contraseñas
echo "$(cmage "Política de contraseñas")"
minlen=$(grep -E '^minlen' /etc/security/pwquality.conf | awk '{print $3}')
minclass=$(grep -E '^minclass' /etc/security/pwquality.conf | awk '{print $3}')
history=$(grep -E '^remember' /etc/pam.d/system-auth /etc/pam.d/common-password 2>/dev/null | awk '{print $NF}' | head -n1)
faillimit=$(grep -E '^deny' /etc/security/faillock.conf /etc/pam.d/system-auth 2>/dev/null | awk '{print $NF}' | head -n1)

cinfo "Longitud mínima" "$minlen"
cinfo "Clases mínimas" "$minclass"
cinfo "Histórico permitido" "$history"
cinfo "Intentos antes de bloqueo" "$faillimit"

# ⏱️ Servicio de tiempo apuntando a 1.1.1.1
echo "$(cmage "Sincronización de tiempo")"
ntp_target="1.1.1.1"
ntp_config=$(grep -E "$ntp_target" /etc/chrony.conf /etc/ntp.conf 2>/dev/null)

if [ -n "$ntp_config" ]; then
  cinfo "Servidor NTP" "$(cverde "$ntp_target OK")"
else
  cinfo "Servidor NTP" "$(crojo "No apunta a $ntp_target")"
fi