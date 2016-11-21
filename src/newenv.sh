#!/bin/bash
#FRONTCONTROLLER
source $NEWENV_CONF
source functions.sh
usage="Usage: newenv [command] [args]

COMMANDS:

  add       create new container (in current dir by default). See 'newenv add --help ' for details
  conf      Select or define config variables. See 'newenv conf --help for details'
"
#RUN ROUTER
parse_command $@
