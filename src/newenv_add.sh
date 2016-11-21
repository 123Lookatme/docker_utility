#!/bin/bash
usage="Usage: newenv add [INSTANCE] [OPTIONS] [ARGS]

!NOTE: RUN COMMANDS FROM PROJECT DIRRECTORY WHERE YOU WANT TO ADD CONTAINER INSTANCE
       OR USE -p=/full_path insted !

Creating new container of INSTANCE
Where INSTANCE - library folder with Dockerfile at $DOCKERFILES
NOTE: You can include your own library. See 'newenv conf --help'

Options:
  -a            making container starting with system startup

  -c=value      replacing default container entrypoint ( -c=/bin/bash ) 
                For more information check 'docker run --help' where [COMMAND] equal -c

  -h=value      adding container alias to host file. Where [value] = alias

  -m=value      Path where container apperars(Default: ./)
                !NOTE: Container network && name will be using this value
                for override use -g=[GroupName]

  -g=value      Overriding container's group name && network name

Args:
  You can run container with additional options provided by docker run [OPTIONS]
  For example -p 8080:80. For more information see 'docker run --help'
"
parse_instance "$@"
parse_options "${@:2}"
IMAGENAME=$ENV"_"$INSTANCE
[ "$HOSTDIR" ] && HOST_PATH="$HOSTDIR" || HOST_PATH="$NEWENV_USER_PATH"
[ ! "$GROUP" ] && GROUP=$(basename "$HOST_PATH")
CONTAINER=$GROUP"_"$INSTANCE
BUILD_EXISTS=$(check_build "$IMAGENAME")
COMMANDS="--net $GROUP --network-alias $INSTANCE --name $CONTAINER --env MOUNTDIR=$MOUNTDIR -v $HOST_PATH"/"$ENV"/"$INSTANCE:$MOUNTDIR"
[ "$COMMAND" ] && COMMANDS+=" --entrypoint $COMMAND"
[ "$ARGS" ] && COMMANDS+=" $ARGS"
[ "$HOSTALIAS" ] && COMMANDS+=" --hostname $HOSTALIAS"
[ "$AUTOSTART" ] && COMMANDS+=" --restart unless-stopped"

#FACTS
echo -e "$(tput setaf 2)Gathering facts...$(tput sgr 0)" 
Facts="Facts:\n"

[ $(check_container_exists $CONTAINER) ] && echo -e "$(tput setaf 1)Container Allready exists: $CONTAINER$(tput sgr 0)" && exit 1
if [ ! "$BUILD_EXISTS" ];then
  [[ "$(check_dockerfile $NEWENV_INCLUDE/$INSTANCE)" ]] && DOCKER_FILE_PATH="$NEWENV_INCLUDE/$INSTANCE" || [[ "$(check_dockerfile $DOCKERFILES/$INSTANCE)" ]] && DOCKER_FILE_PATH="$DOCKERFILES/$INSTANCE"
  [ ! "$DOCKER_FILE_PATH" ] && echo -e "$(tput setaf 1)Dockerfile not found in dirrectories:\n\t$DOCKERFILES"/"$INSTANCE\n\t$NEWENV_INCLUDE/$INSTANCE$(tput sgr 0)" && exit 1 
fi

Facts="$Facts  Image:\n"
if [ "$BUILD_EXISTS" ]
then
  Facts="$Facts - Existed image will be used: \"$IMAGENAME\"\n"
else
  Facts="$Facts - New image will be created:\t\t \"$IMAGENAME\"\n  - From Dockerfile \"$DOCKER_FILE_PATH\"\n"
fi
Facts="$Facts  Container:\n  - name:\t\t \"$CONTAINER\" (Use: '-g=value' to change)\n  - mount folder:\t  \"$HOST_PATH"/"$ENV"/"$INSTANCE\" (Use: '-m=full_path' to change)\n"
if [ -d $HOST_PATH"/"$ENV"/"$INSTANCE ];then
  Facts="$Facts $(tput setaf 1)ATTENTION: Mounted folder \"$HOST_PATH"/"$ENV"/"$INSTANCE\" is not empty\n All changes will be rewrited\n$(tput sgr 0)"
fi
if [ "$COMMAND" ];then
  Facts="$Facts - command on run:\t \"$COMMAND\"\n"
fi
if [ $ARGS ];then 
  Facts="$Facts - options on run:\t  \"$ARGS\"\n"
fi
if [ "$(check_network $GROUP)" ]
then
  Facts="$Facts Network:\n - Existed network will be used: \"$GROUP\"\n" 
else
  Facts="$Facts Network:\n - New network will be created: \"$GROUP\"\n" 
fi
if [ "$HOSTALIAS" ];then
  Facts="$Facts - New host alias will be created: \"$HOSTALIAS\"\n"
fi
if [ "$AUTOSTART" ];then
  Facts="$Facts Note: New container will be added to autostart on system boot\n"
fi 

#CONFIRM
confirm $Facts && echo "$(tput setaf 2)Starting...$(tput sgr 0)" || exit 0

#BUILD
if [ ! "$(check_build $IMAGENAME)" ];then
  RESULT=$(execute_command build $DOCKER_FILEPATH $IMAGENAME)
  [ $? -eq 0 ] && echo -e "$RESULT" || echo -e "$RESULT" && exit 1
fi

if [ ! "$(check_network $GROUP)" ];then
    RESULT=$(execute_command network $GROUP)
    [ $? -eq 0 ] && echo -e "$(tput setaf 2)$RESULT$(tput sgr 0)\n" || echo -e "$RESULT" && exit 1 
fi

#HOSTALIAS
if [ "$HOSTALIAS" ];then
  IP=$(generate_ip $GROUP)
  [ $? -eq 1 ] && echo -e "$(tput setaf 1)Unable add to hosts.Docker Subnet error\n$(tput sgr 0)\n" && exit 1
  COMMANDS+=" --ip $IP"
fi

#RUN
RESULT=$(execute_command run $INSTANCE $COMMANDS)
[ $? -eq 0 ] && echo -e "$(tput setaf 2)Container successfuly started with id: $RESULT$(tput sgr 0)\n" || echo -e "$RESULT" && exit 1
#ADD DNS
echo "$IP  $HOSTALIAS" >> $DOCKER_DDNS
pkill -x -HUP dnsmasq
echo "$(tput setaf 2)Good bye :)$(tput sgr 0)\n"



