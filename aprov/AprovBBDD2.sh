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
