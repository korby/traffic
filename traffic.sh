#!/bin/bash

function print_usage {
	echo "usage: $0 [-u username -p userpassword] URL number-of-clients"
	echo "		    [-u username -p userpassword] -f URLS-list-file number-of-clients"
}

function traffic_stats {
	echo "";
	echo -e $green"What logs say : \n";
	clients_logs=`ls $log_dir/traffic-log-*`
	for file in $clients_logs ; do
		echo $file $(tail -3 /tmp/traffic-log-1 | tr '\n' ' ')
	done
	echo -e $std
}

if [ "$#" -lt 2 ] ; then
	echo "missing arguments"
	print_usage
	exit 1
fi

red="\033[31m"
green='\033[32m'
yellow='\033[33m'
std="\033[0m"
log_dir=/tmp
file=""
url="${@: -2}"
iter="${@: -1}"
user=""
passwd=""
while getopts f:u:p: options
do	case "$options" in
	f)	 file="$OPTARG"
		  ;;
	u)   user="$OPTARG"
          ;;
 	p)   passwd="$OPTARG"
          ;;
	[?]) print_usage
		exit 1;;
	esac
done

rm -rf ./traffic-work-*
rm -f $log_dir/traffic-log-*
[ -f $log_dir/traffic-err ] && rm $log_dir/traffic-err

echo "Launch clients"

auth="";
if [ ! "$user" = "" ] && [ ! "$passwd" = "" ] ; then
	auth="--user=$user --password=$passwd --auth-no-challenge";
fi

c=1
while [ $c -le $iter ]
do
  if [ "$file" = "" ] ; then
	exec wget -E -H -p -P "traffic-work-$c" $url $auth -o $log_dir/traffic-log-$c 2>$log_dir/traffic-err &
  elif [ -f $file ] ; then
	exec wget -E -H -p -P "traffic-work-$c" -i $file $auth -o $log_dir/traffic-log-$c 2>$log_dir/traffic-err &
  else
  	echo "$file : No such file"
  	exit 1
  fi
  
  echo -ne '\r' "$c client(s) crawling"

  (( c++ ))
  sleep 1
done
echo ""
echo -e $yellow"Now showing logs of last client, press Ctrl + c to exit"$std
echo ""
trap traffic_stats SIGINT
sleep 2
cat $log_dir/traffic-err
tail -f $log_dir/traffic-log-$iter
