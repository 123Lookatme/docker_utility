#!/bin/bash

create_data_dir() {
  mkdir -p ${MOUNTDIR}"/data" && \
  chmod -R 0700 ${MOUNTDIR}"/data" && \
  chown -R ${USER}:${MYSQL_USER} ${MOUNTDIR}"/data"
  chgrp -R ${USER} ${MOUNTDIR}"/data"
}

create_log_dir() {
  mkdir -p ${MOUNTDIR}"/log" && \
  chmod -R 0755 ${MOUNTDIR}"/log" && \
  chown -R ${USER}:${USER} ${MOUNTDIR}"/log"
}

create_config_dir(){
  mkdir -p ${MOUNTDIR}"/config" && \
  chmod -R 0755 ${MOUNTDIR}"/config" && \
  chown -R ${USER}:${USER} ${MOUNTDIR}"/config"
}

apply_config_changes(){
  sed -i '/general_log_file/c\general_log_file= '"$MOUNTDIR"'/log/mysql.log' /etc/mysql/my.cnf && \
  sed -i '/log_error/c\log_error='"$MOUNTDIR"'/log/error.log' /etc/mysql/my.cnf && \
  sed -i '/datadir/c\datadir='"$MOUNTDIR"'/data' /etc/mysql/my.cnf && \
  sed -i '/!includedir/c\!includedir '"$MOUNTDIR"'/config' /etc/mysql/my.cnf
}

listen_on_all_interfaces() {
  cat > ${MOUNTDIR}"/config/mysql-listen.cnf" <<EOF
[mysqld]
bind = 0.0.0.0
EOF
}


create_database_and_privileges(){
  echo "Installing database..."
  mysql_install_db --user=mysql >/dev/null 2>&1
  echo "Starting MySQL server..."
  /usr/bin/mysqld_safe >/dev/null 2>&1 &
  timeout=30
    while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
    do
      timeout=$(($timeout - 1))
      if [ $timeout -eq 0 ]; then
        echo "Could not connect to mysql server. Aborting..."
        exit 1
      fi
      sleep 1
    done
  echo "Grant privileges for root..."
  mysql -e  "GRANT ALL PRIVILEGES ON  *.* TO root@'%'"
  echo "Shuting down mysql..."
  /usr/bin/mysqladmin shutdown
}

create_data_dir
create_log_dir
create_config_dir
apply_config_changes
listen_on_all_interfaces
create_database_and_privileges
exec $(which mysqld_safe)
