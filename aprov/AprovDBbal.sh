#!/bin/bash


# Instalación de nginx
sudo apt update
echo "Repositorios actualizados."
sudo apt install haproxy -y
echo "Nginx instalado correctamente."

# Configuración del servidor HAProxy
cd /etc/haproxy/
sudo cp haproxy.cfg haproxy.cfg.bak
cat <<EOF > haproxy.cfg

global
    log /dev/log local0
    maxconn 2000
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp                    
    option  tcplog                 
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

frontend db_front
    bind *:3306
    mode tcp
    default_backend balancea_db

backend balancea_db
    mode tcp
    balance roundrobin
    option tcp-check
    server db1 192.168.30.10:3306 check
    server db2 192.168.30.11:3306 check

EOF

# Habilitar y reiniciar el servicio HAProxy
sudo systemctl enable haproxy
sudo systemctl restart haproxy


# Inhabilitar la red NAT
sudo route del default
echo "Configuración de HAProxy completada."