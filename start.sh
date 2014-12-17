#!/bin/bash

help() {
  cat <<-EOF
usage: $0 [-h|--help] [--mem N] [-nq|--not-quiet] [ui|shell|sbt]
where:
  ui         Use the web UI (default).
  shell|sbt  Use the command-line shell (SBT) interface.
  --mem N    The default memory for Activator is 4096 (MB), which is also used
             to run the non-Hadoop Spark examples. Use a larger integer value
             N if you experience out of memory errors.
  -nq|--not-quiet
             By default, most Activator output is suppressed when the web UI is
             used. For debugging purposes when running the web UI, use this
             option to show this output.
EOF
}

filter_garbage() {
  quiet=$1
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
    elif [[ -z $quiet ]] ; then
      echo $line
    fi
  done
}

java_opts() {
  mem=$1
  perm=$(( $mem / 4 ))
  (( $perm < 512 )) && perm=512
  echo "-Xms${mem}M -Xmx${mem}M -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=${perm}M"
}

mem=4096
quiet=yes
mode=ui
while [ $# -gt 0 ]
do
  case $1 in
    ui|shell) mode=$1    ;;
    sbt)      mode=shell; echo "Using shell mode" ;;
    "")       mode=ui    ;;
    -h|--h*)
      help
      exit 0
      ;;
    --mem)
      shift
      mem=$1
      ;;
    -nq|--not-quiet)
      quiet=
      ;;
    *)
      echo "Unrecognized argument $1"
      help
      exit 1
      ;;
  esac
  shift
done

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
ARGS=(-Dhttp.address=0.0.0.0 -Dhttp.port=9999 $mode)
JAVA_OPTS=$(java_opts $mem)
echo JAVA_OPTS=\"$JAVA_OPTS\" $HOME/activator/activator ${ARGS[@]}
log="$dir/activator.log"
[[ -z $NOOP ]] || exit 0
if [[ $mode = ui ]]
then
  echo "Running the Web UI. Writing all activity to $log"
  JAVA_OPTS="$JAVA_OPTS" $HOME/activator/activator ${ARGS[@]} 2>&1 | tee "$log" | filter_garbage $quiet
else
  echo "Running the command shell. Writing all activity to $log"
  JAVA_OPTS="$JAVA_OPTS" $HOME/activator/activator ${ARGS[@]} 2>&1 | tee "$log"
fi
