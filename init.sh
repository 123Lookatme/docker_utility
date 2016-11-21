#!/bin/bash
#/path_to_init/init.sh
NEWENV_PATH=`dirname $(readlink -f $0)`
NEWENV_USER="newenv"
NEWENV_CONF=$NEWENV_PATH"/src/newenv.conf"
NEWENV_DNS=$NEWENV_PATH/newenv-hosts

#install docker if not exists
[ ! "$(command -v docker)" ] && curl -sSL https://get.docker.com | sudo sh

#instal dnsmasq if not exists
apt-get install dnsmasq -y
touch $NEWENV_DNS
cat > /etc/dnsmasq.d/newenv-dns <<DNS
addn-hosts=$NEWENV_DNS
interface=docker0
#bind-interfaces
DNS
sed -i '/user=/c\user='"$NEWENV_USER" /etc/dnsmasq.conf
service dnsmasq restart

#make config
cat > $NEWENV_CONF <<CONF
ENV="newenv"
NEWENV_PATH=$NEWENV_PATH
NEWENV_USER=$NEWENV_USER
DOCKERFILES=$NEWENV_PATH/lib
DOCKER_DDNS=$NEWENV_DNS
NEWENV_INCLUDE=""
MOUNTDIR="/host"
CONF

#make user and add to docker group
getent passwd $NEWENV_USER > /dev/null 2>&1

if [ ! "$?" -eq 0 ]; then
  useradd -M $NEWENV_USER --shell /bin/false
  usermod -G docker $NEWENV_USER
fi

chown $NEWENV_USER -R $NEWENV_PATH
chmod a+x -R $NEWENV_PATH"/src"

#make executable
cat > /usr/sbin/newenv <<EOF
#!/bin/bash
if [ ! -f "$NEWENV_PATH/src/newenv.sh" ];then
  echo "newenv scripts not found at $NEWENV_PATH"
fi
cd $NEWENV_PATH/src
NEWENV_CONF=$NEWENV_CONF NEWENV_USER_PATH=\$OLDPWD sudo -u $NEWENV_USER -H -E /bin/bash ./newenv.sh \$@
EOF
chmod 555 /usr/sbin/newenv
echo "$(tput setaf 2)Install complete successfuly!$(tput sgr 0)"
echo "$(tput setaf 2)Note: Use 'newenv conf -i=/path_to_lib' to add your own library with Dockerfiles. $(tput sgr 0)"
newenv --help

