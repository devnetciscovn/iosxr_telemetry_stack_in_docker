# iosxr_telemetry_stack_in_docker
IOSXR Telemetry Application Stack in Docker

## Installation and running IOS-XR Docker Telemery Stack

* Prerequisites
    * Docker (20.10.2 or above)
    * Docker-compose (1.8.0 or above)

Download the iosxr_telemetry_stack_in_docker git repo using git clone command

```
git clone https://wwwin-github.cisco.com/sargandh/iosxr_telemetry_stack_in_docker.git
```

All the docker commands should be used under iosxr_telemetry_stack_in_docker.

So after git clone command, change working directory to cd iosxr_telemetry_stack_in_docker
```
cd iosxr_telemetry_stack_in_docker
```
1. Create influxDB database with 30 days retention policy

```
sudo docker run --rm \
    --env-file config_influxdb.env \
    -v iosxrtelemetrystackindocker_influxdb:/var/lib/influxdb \
    -v $PWD/influxdb/scripts:/docker-entrypoint-initdb.d \
    influxdb:1.8.3 /init-influxdb.sh
```

Ensure the below output is present on the logs which ensures that iql database creation script is run.
```
[httpd] 127.0.0.1 - - [26/Jan/2021:09:24:26 +0000] "POST /query?chunked=true&db=&epoch=ns&q=CREATE+USER+%22admin%22+WITH+PASSWORD+%5BREDACTED%5D+WITH+ALL+PRIVILEGES HTTP/1.1" 200 57 "-" "InfluxDBShell/1.8.3" 489f977f-5fb8-11eb-8002-0242ac110002 120126
/init-influxdb.sh: running /docker-entrypoint-initdb.d/influxdb-init.iql

```
2. Start the docker telemetry stack using docker-compose up
```
sudo docker-compose up -d
```

3.  Stopping the telemetry stack
* Stop the telemetry stack without removing the database
```
sudo docker-compose down
```
* Stop the docker telemetry stack and remove the influxdb database iosxrtelemetrystackindocker_influxdb  

NOTE: The existing influxdb time series data will be lost.

```
sudo docker-compose down -v
```

## Access IOS-XR Docker Telemery Stack

Access the grafana UI using the docker host_ip:3000 port number

```
http://<IP>:3000/login
```
Sample SNMP Metrics
![Alt text](/images/IOSXR_Device_Metrics_SNMP.png?raw=true "SNMP metrics collected by telegraf")
