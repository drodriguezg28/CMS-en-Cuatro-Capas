#!/bin/bash

# Instalación de nginx
sudo apt update
echo "Repositorios actualizados."

sudo apt install nginx -y
echo "Nginx instalado correctamente."

# Configuración del grupo de servidores backend
cd /etc/nginx/
if [ ! -f conf.d/web-balancer.conf ]; then
    sudo touch conf.d/web-balancer.conf
fi


cat <<EOF > conf.d/web-balancer.conf

upstream backend_servers {
    roundrobin;
    server 192.168.10.10:80;
    server 192.168.10.11:80;
}

EOF

echo "Configuración del grupo de servidores backend creada."

#Configuración del balanceador de carga
cp sites-available/default sites-available/default.bak
sudo cat <<'EOF' > sites-available/default
server {
    listen 80;
    listen [::]:80;

    server_name _;

    location / {
        proxy_pass http://backend_servers;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }    
}

EOF
echo "Archivo de configuración del balanceador de carga creado."
# Habilitar nuevo sitio y deshabilitar el por defecto
sudo systemctl enable nginx
sudo systemctl reload nginx
echo "Balanceador de carga configurado y activo."

