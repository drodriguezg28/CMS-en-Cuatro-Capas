#!/bin/bash

# Instalación de NFS
sudo apt update
sudo apt install nfs-kernel-server -y
echo "NFS se ha instalado correctamente y está activo."

# Crear el directorio para compartir vía NFS
sudo mkdir -p /var/www/php

#Clonación del repositorio
apt install -y git
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
sudo cp -r iaw-practica-lamp/src/* /var/www/php
echo "Repositorio clonado y archivos copiados a /var/www/php."

# Eliminación de los restos del repositorio clonado 
sudo rm -r iaw-practica-lamp
echo "Repositorio clonado eliminado."

#configurar NFS para compartir el directorio /var/www/html
echo "/var/www/php    192.168.10.10(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/var/www/php    192.168.10.11(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo "NFS se ha configurado para compartir el directorio /var/www/html."


# Inhabilitar la red NAT
#sudo route del default
echo "Configuración de MariaDB y de la base de datos completado."
