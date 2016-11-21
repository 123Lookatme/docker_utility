#!/bin/bash
usage="Usage: newenv conf [flag]/[flag=value]

FLAGS:

  -i        By default newenv search instance folder with Docker file in its own library.
	    This flag including second path with library to search at
            NOTE: if not set - home dirrectory will be second place to search instance folder

  -m        mounted folder name whitch will be accessable in container
"
NEWENV_CONF=$NEWENV_PATH"/src/newenv.conf"
parse_conf $@
