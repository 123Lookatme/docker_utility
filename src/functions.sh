#!/bin/bash
parse_command() {
  case "$1" in
    add)
      . newenv_add.sh "${@:2}"
      shift
      ;;
    -h|--help)
    echo "$usage"
    exit
    ;;
    conf)
    . newenv_conf.sh "${@:2}"
    shift
    ;;
    *) printf "illegal command: %s\n" "$1" >&2
    echo "$usage" >&2
    exit 1
    ;;
  esac
}

parse_instance(){
case "$1" in
  -h|--help)
    echo "$usage"
	exit
    ;;
  [a-z]*|[A-Z]*)
	INSTANCE=$1
	shift
	;;
  *) printf "illegal instance: %s\n" "$1" >&2
	echo "$usage" >&2
	exit 1
	;;
esac

}

parse_conf(){
case "$1" in
  -h|--help)
    echo "$usage"
	exit
    ;;
  -i)
    echo "$NEWENV_INCLUDE"
    shift
    ;;
  -i=*)
    sed -i '/NEWENV_INCLUDE/c\NEWENV_INCLUDE='"${@#*=}" $NEWENV_CONF
    echo "${@#*=}"
    shift
    ;;
  *) printf "illegal flag: %s\n" "$1" >&2
	echo "$usage" >&2
	exit 1
	;;
esac
}

parse_options() {
for arg in "$@"
  do
   case "$arg" in
    -c=*) COMMAND+="${arg#*=}"
    shift
    ;;
    -m=*) HOSTDIR="${arg#*=}"
    shift
    ;;
    -h=*) HOSTALIAS="${arg#*=}"
    shift
    ;;
    -a) AUTOSTART=1
    shift
    ;;
    -g=*) GROUP="${arg#*=}"
    shift
    ;;
    *) ARGS+="$arg "
    shift
    ;;
  esac
done
}

confirm () {
    # call with a prompt string or use a default
    echo -e $@
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

execute_command(){
  case "$1" in
  run)
    COMMAND=$(run_command "${@:2}")
    shift
    ;;
  network)
    COMMAND=$(network_command "${@:2}")
    shift
    ;;
  *) printf "illegal command: %s\n" "$1" >&2
    echo "$usage" >&2
    exit 1
    ;;
esac

echo -e "$(tput setab 7)$(tput setaf 1)$COMMAND$(tput sgr 0)\n"
RESULT=`$COMMAND 2>&1`
ERROR=$(echo "$RESULT" | egrep -i "error|conflict|unable|requires")
[ ! "$ERROR" ] && echo -e "$(tput setaf 2)$RESULT$(tput sgr 0)\n" || (echo "$(tput setaf 1)Docker error: \"$ERROR\"$(tput sgr 0)" && exit 1)
}

check_container_exists(){
  docker ps -a --filter="name=$1" -q | xargs
}

check_dockerfile(){
  [ ! -f $1"/Dockerfile" ] || echo 1
}

check_build(){
 docker images $1 -q
}

check_network(){
  docker network ls | egrep "+\s+("$1")\s+"
}

build_command(){
  echo "docker build $1 -t $2"
}

run_command(){
  echo "docker run -id $2 $1"
}

network_command(){
  echo "docker network create --subnet $(generate_subnet) $1"
}

array_contains () {
    local seeking=$1; shift
    local in=1
    for element; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

get_network_subnet(){
  docker network inspect $1 --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>&1
}

get_iprange(){
 docker network inspect $1 --format '{{range .Containers}}{{.IPv4Address}} {{end}}' 2>&1
}

generate_subnet(){
MAIN_SUBNET=$(docker network inspect bridge --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | cut -d. -f1-2)
EXISTED_NETWORKS=$(docker network inspect $(docker network ls -q) --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | grep -v '^$' | cut -d. -f1-2)

for (( i=0;i<252;i++ ));do
  SUBNET=$(echo "$MAIN_SUBNET + 0.0$i" | bc)
  $(array_contains $SUBNET $EXISTED_NETWORKS) && continue || echo $SUBNET".0.0/16" && exit 0
done
}

generate_ip(){
  for ip in $(seq -f "$(echo $(get_network_subnet $1) | cut -d. -f1-3).%g" 2 10); do 
    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; 
	then
	  exit 1
	else
	 $(array_contains $ip"/16" $(get_iprange $1)) && continue || echo $ip && exit 0
    fi
 done
}



