#!/bin/sh

n_requests=1000
n_c_requests=5

function usage
{
  echo
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo
  echo "  -h, --help             Output usage information"
  echo "  -r, --requests         Number of requests to perform"
  echo "  -c, --concurrency      Number of multiple requests to make at a time"
  exit 1
}

while [ "$1" != "" ]; do
  case $1 in
    -r | --requests )           shift
    n_requests=$1
    ;;

    -c | --concurency )         shift
    n_c_requests=$1
    ;;

    -h | --help )
    usage
    ;;

    * )
    usage

  esac
  shift
done


ab -n $n_requests -c $n_c_requests -T 'application/x-www-form-urlencoded' -p post.txt http://localhost:3001/
