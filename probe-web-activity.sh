#!/bin/bash
# For remain, here are status linux codes :
# D Uninterruptible sleep (usually IO)
# R Running or runnable (on run queue)
# S Interruptible sleep (waiting for an event to complete)
# T Stopped, either by a job control signal or because it is being traced.
# W paging (not valid since the 2.6.xx kernel)
# X dead (should never be seen)
# Z Defunct ("zombie") process, terminated but not reaped by its parent.

log_file="/var/log/probe-web-activity.log"
# default 300, 15 minutes
iter=300;
apache_port=`netstat -lntup | grep apache | cut -d: -f 4`

# num of connexion established, num of apache processes, apache ram used average, total apache ram used
echo "load average; global cpu usage; global swap memory usage; num of connexion established;num of apache processes;apache ram used average from ps;total apache ram used from ps;apache ram used average from top;total apache ram used from top; %cpu/apache process from ps; %cpu apache global from ps;%cpu/apache process from top; %cpu apache global from top; apache total proc by status" > $log_file;
  
function log_activity {
  load_average=`top -bn 1 | grep "load" | awk -Faverage: '{print $2}'`
  load_cpu=`top -bn 1 | grep "%Cpu(s)" | cut -d" " -f3`
  load_swap=`top -bn 1 | grep "Swap" | awk -Fused '{print $1}' | cut -d" " -f6-`
  conn_active=`netstat -pan | grep ESTABLISHED | grep -c :$apache_port`
  proc_ram_ps=`ps -C apache2 -O rss | gawk '{ count ++; sum += $2 }; END {count --; print count";"sum/1024/count" Mo;"sum/1024" Mo" ;};'`
  proc_ram_top=`top -bn 1 | grep apache2 | sed "s/,/./g" | gawk '{ count ++; sum += $10 }; END {print sum/count" Mo;"sum" Mo" ;};'`
  cpu_ps=`ps -C apache2 -O %cpu | gawk '{ count ++; sum += $2 }; END {count --; print sum/count" %;"sum" %" ;};'`
  cpu_top=`top -bn 1 | grep apache2 | sed "s/,/./g" | gawk '{ count ++; sum += $9 }; END {print sum/count" %;"sum" %" ;};'`
  apache_proc_S=`top -bn 1 | grep "apache" | grep "S" | wc -l`
  apache_proc_D=`top -bn 1 | grep "apache" | grep "D" | wc -l`
  apache_proc_R=`top -bn 1 | grep "apache" | grep "R" | wc -l`
  apache_proc_T=`top -bn 1 | grep "apache" | grep "T" | wc -l`
  apache_proc_Z=`top -bn 1 | grep "apache" | grep "Z" | wc -l`
  
  echo "$load_average;$load_cpu;$load_swap;$conn_active;$proc_ram_ps;$proc_ram_top;$cpu_ps;$cpu_top;S: $apache_proc_S,D: $apache_proc_D,R: $apache_proc_R,T: $apache_proc_T,Z: $apache_proc_Z" >> $log_file;
}

me_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
me_FILE=$(basename $0)


if [ "$1" != "child" ] ; then # fork the process.
    exec $me_DIR/$me_FILE child "$@" &
    exit 0
fixit 0
fi
                               # now making some stuff
exec >/tmp/outfile
exec 2>/tmp/errfile
exec 0</dev/null

shift

c=1
while [ $c -le $iter ]
do
  log_activity
  (( c++ ))
  sleep 1
done

exit

