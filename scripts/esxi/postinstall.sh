#!/bin/sh
# Post-installation de l'ESXi imbriqué : NTP, politique de sécurité vSwitch,
# portgroup LAB sur vmnic1. À exécuter dans le shell ESXi (busybox ash),
# ex. via SSH une fois ks.cfg terminé.
#
# Post-instalación del ESXi anidado: NTP, política de seguridad del vSwitch,
# portgroup LAB en vmnic1. Ejecutar en el shell de ESXi (busybox ash),
# p.ej. por SSH una vez terminado ks.cfg.
#
# Usage : ./postinstall.sh

set -eu

NTP_SERVERS="0.pool.ntp.org 1.pool.ntp.org"
LAB_VSWITCH="vSwitch1"
LAB_PORTGROUP="LAB"
LAB_UPLINK="vmnic1"

echo "[INFO] Configuration NTP / Configuracion NTP ($NTP_SERVERS)"
for s in $NTP_SERVERS; do
  esxcli system ntp set --server="$s"
done
esxcli system ntp set --enabled=true
/etc/init.d/ntpd restart
echo "[OK] NTP configure et demarre / NTP configurado e iniciado"

echo "[INFO] Politique de securite vSwitch0 (VM imbriquees) / Politica de seguridad vSwitch0 (VMs anidadas)"
esxcli network vswitch standard policy security set --vswitch-name=vSwitch0 \
  --allow-promiscuous=true --allow-forged-transmits=true --allow-mac-change=true
echo "[OK] vSwitch0 : promiscuous / forged transmits / MAC changes = accept"

# Portgroup LAB dedie, rattache a vmnic1, avec la meme politique permissive
# Portgroup LAB dedicado, sobre vmnic1, con la misma politica permisiva
if ! esxcli network vswitch standard list | grep -q "^${LAB_VSWITCH}$"; then
  echo "[INFO] Creation de ${LAB_VSWITCH} sur ${LAB_UPLINK} / Creando ${LAB_VSWITCH} en ${LAB_UPLINK}"
  esxcli network vswitch standard add --vswitch-name="$LAB_VSWITCH"
  esxcli network vswitch standard uplink add --vswitch-name="$LAB_VSWITCH" --uplink-name="$LAB_UPLINK"
else
  echo "[INFO] ${LAB_VSWITCH} existe deja / ${LAB_VSWITCH} ya existe"
fi

if ! esxcli network vswitch standard portgroup list | grep -q "^${LAB_PORTGROUP}$"; then
  echo "[INFO] Creation du portgroup ${LAB_PORTGROUP} / Creando el portgroup ${LAB_PORTGROUP}"
  esxcli network vswitch standard portgroup add --portgroup-name="$LAB_PORTGROUP" --vswitch-name="$LAB_VSWITCH"
else
  echo "[INFO] Portgroup ${LAB_PORTGROUP} existe deja / El portgroup ${LAB_PORTGROUP} ya existe"
fi

esxcli network vswitch standard portgroup policy security set --portgroup-name="$LAB_PORTGROUP" \
  --allow-promiscuous=true --allow-forged-transmits=true --allow-mac-change=true
echo "[OK] Portgroup ${LAB_PORTGROUP} pret sur ${LAB_UPLINK} (politique permissive) / listo (politica permisiva)"

echo "[OK] Post-installation terminee / Post-instalacion terminada"
