#!/bin/bash

help() {
  echo "usage: $0 [-h|--help] [ui|shell|sbt]"
  echo "where: ui is the default and sbt is an alias for shell."
  echo "Use ui for the web-based UI. Use shell/sbt for the command line."
}

filter_garbage() {
  while read line
  do
    if [[ ${line} =~ Please.point.your.browser.at ]] ; then
      echo
      echo "=================================================================="
      echo
      echo "    Open your web browser to:   http://$ip:9999"
      echo
      echo "=================================================================="
    elif [[ ${line} =~ play.-.Application.started ]] ; then
      echo $line
    fi
  done
}

case $1 in
  ui|shell) mode=$1    ;;
  sbt)      mode=shell; echo "Using shell mode" ;;
  "")       mode=ui    ;;
  -h|--h*)
    help
    exit 0
    ;;
  *)
    echo "Unrecognized argument $1"
    help
    exit 1
    ;;
esac

dir=$(dirname $0)
ip=$($dir/scripts/getip.sh)

if [[ $mode = ui ]]
then
  umode=$(echo $mode | tr '[a-z]' '[A-Z]')

  echo "=================================================================="
  echo
  echo "    Starting the Spark Workshop in Activator using $umode mode..."
  echo
  echo "=================================================================="
  echo

  sleep 2
fi

# Invoke with NOOP=x start.sh to suppress execution:
echo $HOME/activator/activator -Dhttp.address=0.0.0.0 -Dhttp.port=9999 $mode
[[ -z $NOOP ]] || exit 0
if [[ $mode = ui ]]
then
  $HOME/activator/activator -Dhttp.address=0.0.0.0 -Dhttp.port=9999 $mode 2>&1 | tee "$dir/activator.log" | filter_garbage
else
  $HOME/activator/activator -Dhttp.address=0.0.0.0 -Dhttp.port=9999 $mode
fi
