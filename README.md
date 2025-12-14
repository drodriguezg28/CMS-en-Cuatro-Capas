# CMS-en-Cuatro-Capas

Está estructura de un sistema de gestión de usuarios está hecho en una pila LEMP.

---

# ÍNDICE 
1. [Instancias](#instancias)
2. [Arquitectura de la Infraestructura](#arquitectura)
3. [Conectividad](#conectividad) 
4. [Scripts de Aprovisionamiento](#aprovisionamiento)
   - [VagrantFile](#vagrantfile)
   - [Balanceador](#balanceador)
   - [Servidores Web](#servidores-web)  
   - [Servidor NFS](#nfs)
   - [Balanceador Base de Datos](#balanceador-db)
   - [Base de Datos 1](#bd1)
   - [Base de Datos 2](#bd2)  
5. [Video de Comprobación](#video-de-comprobación)



# Instancias
**Se crearon los siguientes servidores:**
- Balanceador
- WebServer1
- WebServer2
- NFS
- Balanceador BD (HaProxy)
- BD1
- BD2

# Arquitectura
- **Capa 1 (pública)**: Balanceador de carga Nginx.
- **Capa 2 (privada)**: Dos servidores web Nginx + servidor NFS.
- **Capa 3 (privada)**: Balanceador de base de datos.
- **Capa 4 (privada)**: Servidores de base de datos MariaDB.

# Conectividad
- Solo la **capa 1** tiene acceso desde Internet.

# Aprovisionamiento
Cada máquina se aprovisionará mediante un script **bash**.

## VagrantFile
```ruby

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  
  config.vm.define "balanceadorW" do |balanceadorW|
    balanceadorW.vm.hostname = "balanceadorW"
    balanceadorW.vm.network "public_network"
    balanceadorW.vm.network "private_network", ip: "192.168.10.5", virtualbox__intnet: "redbalweb"
    balanceadorW.vm.network "forwarded_port", guest: 80, host: 8080
    balanceadorW.vm.provision "shell", path: "aprov/AprovBal.sh"
  end  
  
  config.vm.define "webserver1" do |webserver1|
    webserver1.vm.hostname = "webserver1"
    webserver1.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "redbalweb"
    webserver1.vm.network "private_network", ip: "192.168.20.10", virtualbox__intnet: "redwebDBbal"
    webserver1.vm.provision "shell", path: "aprov/AprovWeb.sh"
  end
  
  config.vm.define "webserver2" do |webserver2|
    webserver2.vm.hostname = "webserver2"
    webserver2.vm.network "private_network", ip: "192.168.10.11", virtualbox__intnet: "redbalweb"
    webserver2.vm.network "private_network", ip: "192.168.20.11", virtualbox__intnet: "redwebDBbal"
    webserver2.vm.provision "shell", path: "aprov/AprovWeb.sh"
  end  
  
  config.vm.define "serverNFS" do |serverNFS|
    serverNFS.vm.hostname = "serverNFS"
    serverNFS.vm.network "private_network", ip: "192.168.10.12", virtualbox__intnet: "redbalweb"  
    serverNFS.vm.provision "shell", path: "aprov/AprovNFS.sh"
  end
  
  config.vm.define "balanceadorDB" do |balanceadorDB|
    balanceadorDB.vm.hostname = "balanceadorDB"
    balanceadorDB.vm.network "private_network", ip: "192.168.20.5", virtualbox__intnet: "redwebDBbal"
    balanceadorDB.vm.network "private_network", ip: "192.168.30.5", virtualbox__intnet: "redDBbalDB"
    balanceadorDB.vm.provision "shell", path: "aprov/AprovDBBal.sh"
  end
  
  config.vm.define "db1" do |db1|
    db1.vm.hostname = "db1"
    db1.vm.network "private_network", ip: "192.168.30.10", virtualbox__intnet: "redDBbalDB"
    db1.vm.provision "shell", path: "aprov/AprovBBDD1.sh"
  end
  
  config.vm.define "db2" do |db2|
    db2.vm.hostname = "db2"
    db2.vm.network "private_network", ip: "192.168.30.11", virtualbox__intnet: "redDBbalDB"
    db2.vm.provision "shell", path: "aprov/AprovBBDD2.sh"
  end
end
```
***IP's de cada instancia:***
- Balanceador
     1. Interfaz de red Pública
     2. Interfaz de red redbalweb: ```192.168.10.5```
- WebServer1
     1. Interfaz de red redbalweb: ```192.168.10.10```
     2. Interfaz de red redwebDBbal: ```192.168.20.10```
- WebServer2
     1. Interfaz de red redbalweb: ```192.168.10.11```
     2. Interfaz de red redwebDBbal: ```192.168.20.11```
- NFS
     1. Interfaz de red redbalweb: ```192.168.10.12```
- Balanceador DB
     1. Interfaz de red redwebDBbal: ```192.168.20.5```
     2. Interfaz de red redDBbalDB: ```192.168.30.5```
- DB1
     1. Interfaz de red redDBbalDB: ```192.168.30.10```
- DB2
     1. Interfaz de red redDBbalDB: ```192.168.30.11```

## Balanceador 
```sh
#!/bin/bash

# Instalación de Nginx
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

```
***Este script realiza lo siguiente:***
- Instalación de Nginx.
- Configuración de los servidores backend
- Configuración del balanceador de carga en Nginx

## Servidores Web
```bash
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
#sudo route del default
echo "Configuración de MariaDB y de la base de datos completado."
```
***Este script realiza lo siguiente:***
- Instalación de los paquetes Nginx y NFS Common (NFS Cliente).
- Montaje del directorio compartido a través de NFS
- Hacer un backup del site default
- Configuración de un sitio web con Nginx
- Inhabilitación de la red

## NFS
```bash
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
```
***Este script realiza lo siguiente:***
- Instalación del servidor NFS.
- Descarga del sistema de gestión de usuarios, a través de un repositorio. 
- Configuración de los directorios compartidos
- Inhabilitación de la red

## Balanceador DB
```sh
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
```
***Este script realiza lo siguiente:***
- Instalación de HaProxy
- Configuración de HaProxy
- Inhabilitación de la red

## BD1
```bash
#!/bin/bash

# Instalar MariaDB
sudo apt update
sudo apt install -y mariadb-server
echo "MariaDB se ha instalado correctamente."

sudo systemctl start mariadb
sudo systemctl enable mariadb
echo "Servicio de MariaDB iniciado y habilitado para iniciar al arrancar el sistema."

# Configurar la base de datos y el usuario
mysql -u root <<MYSQL_SCRIPT
CREATE USER 'daniel'@'192.168.30.%' IDENTIFIED BY '123456789';
CREATE USER 'daniel'@'192.168.20.%' IDENTIFIED BY '123456789';
GRANT update, insert, delete, select ON interfaz.* TO 'daniel'@'192.168.30.%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Permitir conexiones remotas modificando el archivo de configuración
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
echo "MariaDB permite conexiones."

#Clonar el repositorio para añadir el script de sql
sudo apt install -y git
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
echo "Repositorio clonado."

# Importar el script SQL
mysql -u root interfaz < iaw-practica-lamp/db/database.sql
echo "Base de datos importada correctamente."

# Eliminar el repositorio clonado 
sudo rm -r iaw-practica-lamp
echo "Restos del repositorio clonado eliminado."

sudo systemctl stop mariadb.service

cd /etc/mysql/mariadb.conf.d/
cp 60-galera.cnf 60-galera.cnf.bak
cat <<EOF > 60-galera.cnf

[galera]
wsrep_on                 = ON
wsrep_cluster_name       = "Cluster MariaDB"
wsrep_cluster_address    = gcomm://192.168.30.10,192.168.30.11
binlog_format            = row
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2
bind_addres = 0.0.0.0
wsrep_node_address = 192.168.30.10 
wsrep_node_name ="DB1"
wsrep_provider = /usr/lib/galera/libgalera_smm.so

EOF

galera_new_cluster
sleep 5

sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service

# Inhabilitar la red NAT
sudo route del default
echo "Configuración de HAProxy completada."

```
***Este script realiza lo siguiente:***
- Instalación del servidor MariaDB
- Creación de un Base de Datos y un usuario
- Asignación de permisos al usuario sobre la Base de Datos
- Permisos a conexiones remotas
- Clonación del script de SQL
- Creación de la tabla **users** a través del archivo clonado.
- Creación del cluster
- Inhabilitación de la red

## BD2
```sh
#!/bin/bash

# Instalar MariaDB
sudo apt update
sudo apt install -y mariadb-server
echo "MariaDB se ha instalado correctamente."

sudo systemctl start mariadb
sudo systemctl enable mariadb
echo "Servicio de MariaDB iniciado y habilitado para iniciar al arrancar el sistema."

# Configuración de Galera en el nodo 2
cd /etc/mysql/mariadb.conf.d/
cp 60-galera.cnf 60-galera.cnf.bak
cat <<EOF > 60-galera.cnf

[galera]
wsrep_on                 = ON
wsrep_cluster_name       = "Cluster MariaDB"
wsrep_cluster_address    = gcomm://192.168.30.10,192.168.30.11
binlog_format            = row
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2
bind_addres = 0.0.0.0
wsrep_node_address = 192.168.30.11
wsrep_node_name ="DB2"
wsrep_provider = /usr/lib/galera/libgalera_smm.so

EOF

sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service

# Inhabilitar la red NAT
sudo route del default
echo "Configuración de MariaDB y de la base de datos completado."

```
***Este script realiza lo siguiente:***
- Instalación del servidor MariaDB
- Creación del cluster
- Inhabilitación de la red


# Video de comprobación.
[Video](https://drive.google.com/file/d/10riB_BQPf4KMmMyxlJQJJdWqNrQdRjRC/view?usp=drive_link)


















