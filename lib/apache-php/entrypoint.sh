#!/bin/bash
create_data_dir() {
  mkdir -p ${MOUNTDIR}"/www" && \
  chmod -R 755 ${MOUNTDIR}"/www" && \
  chown -R ${USER}:${USER} ${MOUNTDIR}"/www"
  chgrp -R ${USER} ${MOUNTDIR}"/www"
}

create_log_dir() {
  mkdir -p ${MOUNTDIR}"/log" && \
  chmod -R 0755 ${MOUNTDIR}"/log" && \
  chown -R ${USER}:${USER} ${MOUNTDIR}"/log"
}

create_config_dir(){
  mkdir -p ${MOUNTDIR}"/config" && \
  mkdir -p ${MOUNTDIR}"/config/conf-enabled" && \
  mkdir -p ${MOUNTDIR}"/config/sites-enabled" && \
  chmod -R 0755 ${MOUNTDIR}"/config" && \
  chown -R ${USER}:${USER} ${MOUNTDIR}"/config"
}

apply_config_changes(){
  sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
  sed -i "s/Require all/Require all granted/g" /etc/apache2/apache2.conf && \
  sed -i '/IncludeOptional conf-enabled/c\IncludeOptional '"${MOUNTDIR}"'/config/conf-enabled/*.conf' /etc/apache2/apache2.conf && \
  sed -i '/IncludeOptional sites-enabled/c\IncludeOptional '"${MOUNTDIR}"'/config/sites-enabled/*.conf' /etc/apache2/apache2.conf && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
  sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini && \
  a2enmod rewrite 
}
    
run_server(){
  source /etc/apache2/envvars
  exec apache2 -D FOREGROUND
}

create_data_dir
create_log_dir
create_config_dir
apply_config_changes
run_server
