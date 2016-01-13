#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
args_tab=( $@ )
args_tab_len=${#args_tab[@]}

function traffic_end {
	traffic_stats
	probe "stop_and_get"
	soffice_installed=`locate soffice | grep -e soffice$`
	if [ "$soffice_installed" != "" ] ; then
		files=""
		for host in $probe_hosts
		do
			files=$files" $log_dir/$probe_name-audit-$host.csv";
		done

		if [ "$files" != "" ] ; then
			echo "You could open these reporting files with Open Office typing these kinds of command"
			for app in $soffice_installed
			do
				echo "$app $files &"
			done
		fi
		
	fi
}

function print_usage {
	echo "usage: $0 [-u username -p userpassword] URL number-of-clients"
	echo "		    [-u username -p userpassword] -f URLS-list-file number-of-clients"
	echo "		    [-s ssh-probinghost-connexion1,ssh-probinghost-connexion2] [-u username -p userpassword] -f URLS-list-file number-of-clients"
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

function probe {
	for host in $probe_hosts
	do
		probe_$1 $host ;
	done

}

function probe_install {
	echo "Checking remote host "$1;
	ssh $1 "bash -c '[ -f $probe_dir/$probe_name.sh ]'"
	if [ "$?" = "0" ] ; then
		echo "Nothing to install, file allready exists";
	else
		echo "Instaling probe's file on the remote host $1:$probe_dir/$probe_name.sh";
		scp ./$probe_name.sh $1:$probe_dir/$probe_name.sh
	fi

}

function probe_start {
	echo "Starting probe on remote host "$1;
	sudo=""
	
	if [ $(ssh $1 "whoami") != "root" ] ; then
		ssh $1 "sudo whoami"
		if [ "$?" = "0" ] && [ $(ssh $1 "sudo whoami") == "root" ] ; then
			sudo="sudo ";
		else
			echo -e $yellow"Warning ! The ssh user used is not root and can't be rooted by sudo"$std
			echo -e $yellow"the probe won't be started or will return not enough informations"$std
		fi
	fi

	ssh $1 $sudo"$probe_dir/$probe_name.sh stop";
	ssh $1 $sudo"$probe_dir/$probe_name.sh";

}

function probe_stop_and_get {
	echo "Stopping probe on $1"
	echo -e $green"Getting probe log of host $1 and save it here : $log_dir/$probe_name-audit-$1.csv..."$std
	scp $1:$probe_log_file $log_dir/$probe_name-audit-$1.csv

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
url="${args_tab[$args_tab_len-2]}"
iter="${args_tab[$args_tab_len-1]}"
user=""
passwd=""
probe_dir=/tmp
probe_name="probe-web-activity"
probe_log_file="/var/log/$probe_name.log"
probe_hosts=""
while getopts f:u:p:s: options
do	case "$options" in
	h)	 print_usage;
		  exit 0;
		  ;;
	f)	 file="$OPTARG"
		  ;;
	u)   user="$OPTARG"
          ;;
 	p)   passwd="$OPTARG"
          ;;
    s)   probe_hosts=$(echo $OPTARG | tr "," "\n");
         probe "install"
         probe "start"
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
  	# for debug:
  	# echo 'executing : exec wget -E -H -p -P "traffic-work-'$c'" '$url' '$auth' -o '$log_dir'/traffic-log-'$c' 2>$log_dir/traffic-err &'
	exec wget -E -H -p -S -P "traffic-work-$c" $url $auth -o $log_dir/traffic-log-$c 2>&1 &
  elif [ -f $file ] ; then
	exec wget -E -H -p -S -P "traffic-work-$c" -i $file $auth -o $log_dir/traffic-log-$c 2>&1 &
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
trap traffic_end SIGINT
sleep 2
tail -f $log_dir/traffic-log-$iter
