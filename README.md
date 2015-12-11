# traffic
Agent and very simple probe for testing performance of a web server

Warning : The probe is mainly made for the Apache webserver and is only tested on Debian.  
Important : Agents not only crawl url, they also download all necessary files (imaes, css, js etc.).

Usage overview
```shell
./traffic.sh http://www.google.com/ 12
```
Here 12 web clients visit the url http://www.google.com/

```shell
./traffic.sh -u toto -p tata http://www.a-protected-preproduction-somewhere.com/ 20
```
Here 20 web clients the url http://www.a-protected-preproduction-somewhere.com/ indicating on each http request the basicauth login/password parameters : toto/tata

```shell
./traffic.sh -f urls.txt 15
```
Here 15 web clients visit all the urls which are in the ./urls.txt files (one line per url)

```shell
./traffic.sh -s root@host1.com,root@host2.com http://www.host.com 18
```
Usefull with many front end server load balanced.  
Here the probe is installed and started on hosts host1.com and host2.com using ssh connection with user root. 
After that 18 web clients visit the url http://www.host.com/ then all probes are stopped and probes' analysis data are collected on localmachine in csv files.
