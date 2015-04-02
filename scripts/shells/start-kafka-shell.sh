#!/bin/bash

host_ip=192.168.59.103:9092
zk_ip=192.168.59.103:2181

function usage
{
  echo
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo
  echo "  -h, --help             Output usage information"
  echo "  -zk, --zookeeper       The zookeeper IP"
  echo "  -hp, --host-ip         The Host IP"
  exit 1
}

while [ "$1" != "" ]; do
  case $1 in
    -zk | --zookeeper )           shift
    zk_ip=$1
    ;;

    -hp | --host-ip )
    host_ip=$1
    ;;

    -h | --help )
    usage
    ;;

    * )
    usage

  esac
  shift
done

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -e HOST_IP=$host_ip -e ZK=$zk_ip -i -t wurstmeister/kafka:0.8.2.0 /bin/bash
