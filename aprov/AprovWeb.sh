#!/bin/bash

# Instalación de nginx y php5
sudo apt update
sudo apt install nginx nfs-common php8.2-fpm php8.2-mysql -y
echo "Nginx y NFS cliente se han instalado correctamente y están activos."

# Montar el sistema de archivos NFS
sudo mkdir -p /var/www/php
echo "192.168.10.12:/var/www/php /var/www/php nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
echo "Sistema de archivos NFS montado en /var/www/php."


# Configurar nginx para servir el
cd /etc/nginx/sites-available/
cp default default.bak

sed -i "s|^root /var/www.*|         root /var/www/php;|" default
sed -i "s|^\sindex.*|         index index.php;|" default
sudo sed -i '/^}/i \
    location ~ \\.php$ {\
        include snippets/fastcgi-php.conf;\
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;\
    }' default

echo "Configuración de nginx actualizada para servir archivos PHP."

# Reiniciar nginx para aplicar los cambios
sudo systemctl restart nginx
echo "Nginx reiniciado. La configuración está activa."


# Inhabilitar la red NAT
sudo route del default
echo "Configuración de nginx completado."
