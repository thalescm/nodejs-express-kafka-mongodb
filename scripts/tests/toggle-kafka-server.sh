#!/bin/sh

pause=false
unpause=false
server=not_a_number

function usage
{
  echo
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo
  echo "  -h, --help             Output usage information"
  echo "  -p, --pause            Pause the server. Note that this command cannot be used togheter with -u"
  echo "  -u, --unpause          Unpause the server. Note that this command cannot be used togheter with -p"
  echo "  -s, --server           The server to be (un)paused, can be 1, 2 or 3"
  exit 1
}

function simultaneously
{
  echo "Pause and unpause cannot be made simultaneously"
  exit 1
}

while [ "$1" != "" ]; do
  case $1 in
    -p | --pause )
    if [ "$unpause" = true ]; then
      simultaneously
    fi
    pause=true
    ;;

    -u | --unpause )
    if [ "$pause" = true ]; then
      simultaneously
    fi
    unpause=true
    ;;


    -s | --server )  shift
    server=$1
    ;;

    -h | --help )
    usage
    ;;

    * )
    usage

  esac
  shift
done

if [ "$unpause" = false ] && [ "$pause" = false ]; then
  echo "error: It was not passed if you want to pause or unpause the server"
  exit 1
fi

if ! [ "$server" -ge 1 -a "$server" -le 3 ] ; then
  echo "error: Server must in range 1 to 3" >&2; exit 1
fi

serverName="kafka$server"

if [ "$pause" = true ] ; then
  pause_id=$(docker ps | grep $serverName | cut -f 1 -d " ")
  docker pause $pause_id
  echo "Paused Container $(docker pause $pause_id): $serverName"
fi

if [ "$unpause" = true ] ; then
  pause_id=$(docker ps | grep $serverName | cut -f 1 -d " ")
  docker unpause $pause_id
  echo "Unpaused Container $(docker unpause $pause_id): $serverName"
fi
