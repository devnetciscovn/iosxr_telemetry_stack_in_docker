# iosxr_telemetry_stack_in_docker
IOSXR Telemetry Application Stack in Docker

Often it requires lot of time to configure the telemetry application stack to see the full capabilities of IOS-XR telemetry streaming.  
The telemetry application stack includes telegraf, influxdb, grafana, pipeline, and more.

The purpose of this project is to preconfigure telemetry application stack (telegraf, influxdb, grafana, et) as docker-compose application along with a number of preconfigured grafana dashboards for router health and network monitoring. 

It all takes a few commands to run whole application stack in docker environment.

The current monitoring dashboards are
   * Health Monitoring dashboard - CPU, memory, interface counters, GigE optical-power, etc
   * BGP Monitoring dashboard - BGP prefix/path monitoring
   * SNMP dashbourd - SNMP based sytem information

## Installation 

* Prerequisites
    * Docker (20.10.2 or above)
    * Docker-compose (1.8.0 or above)

Download the iosxr_telemetry_stack_in_docker git repo using git clone command

```
git clone https://wwwin-github.cisco.com/sargandh/iosxr_telemetry_stack_in_docker.git
```

## Starting iosxr telemetry stack

NOTE: All the docker commands should be used under iosxr_telemetry_stack_in_docker.

```
cd iosxr_telemetry_stack_in_docker
```

1. Create influxDB database with 30 days retention policy.  
Running time series database such as influxdb without any retention policy can easily fill up the server storage due the vast amount of telemetry data.  
Default settting is configured for 30 days/720 hours and can be changed on iql script. 

```
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ more influxdb/scripts/influxdb-init.iql   
CREATE DATABASE mdt_db WITH DURATION 720h SHARD DURATION 6h;
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ 
```

Create influxdb database using the below command
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
2. Configure SNMP credentials if you want to use this app stack as SNMP monitoring dashboard
```
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ more config_telegraf.env 
#telegraf environment variables

#Device SNMP details
SNMP_DEVICE_IP=udp://<Router_Mgmt_IP>:161 #Provide your router's management IP reachable from docker VM
SNMP_COMMUNITY=<community>                 #Provide SNMP version 2 community string
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ 
```

3. Start the iosxr telemetry stack using docker-compose up command

```
sudo docker-compose up -d
```
```
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ sudo docker-compose up -d
Creating network "iosxrtelemetrystackindocker_default" with the default driver
Creating iosxrtelemetrystackindocker_influxdb_1 ... 
Creating iosxrtelemetrystackindocker_influxdb_1 ... done
Creating iosxrtelemetrystackindocker_grafana_1 ... 
Creating iosxrtelemetrystackindocker_telegraf_1 ... 
Creating iosxrtelemetrystackindocker_grafana_1
Creating iosxrtelemetrystackindocker_telegraf_1 ... done
cisco@ubuntu-docker:~/iosxr_telemetry_stack_in_docker$ 
```

## Accessing Telemery Stack GUI

Access the grafana UI using the docker_host_ip:3000 port number  
Docker host IP is the IP address reachable from router mgmt interface towards the Docker VM

```
http://<DOCKER_HOST_IP>:3000/login
Default login credentials - admin/admin
```

## Configure the router for streaming telemetry

1. Enable the below configs on IOS-XR router to start streaming the telemetry data
```
telemetry model-driven
 destination-group DGroup1
  address-family ipv4 <DOCKER_HOST_IP> port 57000
   encoding self-describing-gpb
   protocol grpc no-tls
  !
 !
  sensor-group health
  sensor-path Cisco-IOS-XR-shellutil-oper:system-time/uptime
  sensor-path Cisco-IOS-XR-wdsysmon-fd-oper:system-monitoring/cpu-utilization
  sensor-path Cisco-IOS-XR-nto-misc-oper:memory-summary/nodes/node/summary
 !
 sensor-group optics
  sensor-path Cisco-IOS-XR-controller-optics-oper:optics-oper/optics-ports/optics-port/optics-info
 !
 sensor-group routing
  sensor-path Cisco-IOS-XR-ipv4-bgp-oper:bgp/instances/instance/instance-active/default-vrf/process-info
 !
 sensor-group interfaces
  sensor-path Cisco-IOS-XR-pfi-im-cmd-oper:interfaces/interface-summary
  sensor-path Cisco-IOS-XR-infra-statsd-oper:infra-statistics/interfaces/interface/latest/generic-counters
 !
  subscription health
  sensor-group-id health strict-timer
  sensor-group-id health sample-interval 30000
  destination-id DGroup1
 !
 subscription optics
  sensor-group-id optics strict-timer
  sensor-group-id optics sample-interval 30000
  destination-id DGroup1
 !
 subscription routing
  sensor-group-id routing strict-timer
  sensor-group-id routing sample-interval 30000
  destination-id DGroup1
 !
 subscription interfaces
  sensor-group-id interfaces strict-timer
  sensor-group-id interfaces sample-interval 30000
  destination-id DGroup1
 !
!
commit 
```

2. Verify Telemetry GRPC session status on router
```
RP/0/RP0/CPU0:NCS5508-Core1-DUT#sh telemetry model-driven destination        
Thu Jan 28 16:04:41.099 GMT
  Group Id         Sub                          IP              Port    Encoding            Transport   State       
  -----------------------------------------------------------------------------------------------------------
  DGroup1          health                       217.46.30.20    57000   self-describing-gpb grpc        Active      
      No TLS                
  DGroup1          optics                       217.46.30.20    57000   self-describing-gpb grpc        Active      
      No TLS                
  DGroup1          interfaces                   217.46.30.20    57000   self-describing-gpb grpc        Active      
      No TLS                
  DGroup1          routing                      217.46.30.20    57000   self-describing-gpb grpc        Active      
      No TLS                
RP/0/RP0/CPU0:NCS5508-Core1-DUT#
RP/0/RP0/CPU0:NCS5508-Core1-DUT#sh telemetry model-driven sensor-group 
Thu Jan 28 16:06:08.322 GMT
  Sensor Group Id:health
    Sensor Path:        Cisco-IOS-XR-shellutil-oper:system-time/uptime
    Sensor Path State:  Resolved
    Sensor Path:        Cisco-IOS-XR-wdsysmon-fd-oper:system-monitoring/cpu-utilization
    Sensor Path State:  Resolved
    Sensor Path:        Cisco-IOS-XR-nto-misc-oper:memory-summary/nodes/node/summary
    Sensor Path State:  Resolved

  Sensor Group Id:optics
    Sensor Path:        Cisco-IOS-XR-controller-optics-oper:optics-oper/optics-ports/optics-port/optics-info
    Sensor Path State:  Resolved

  Sensor Group Id:interfaces
    Sensor Path:        Cisco-IOS-XR-pfi-im-cmd-oper:interfaces/interface-summary
    Sensor Path State:  Resolved
    Sensor Path:        Cisco-IOS-XR-infra-statsd-oper:infra-statistics/interfaces/interface/latest/generic-counters
    Sensor Path State:  Resolved

  Sensor Group Id:routing
    Sensor Path:        Cisco-IOS-XR-ipv4-bgp-oper:bgp/instances/instance/instance-active/default-vrf/process-info
    Sensor Path State:  Resolved

RP/0/RP0/CPU0:NCS5508-Core1-DUT#
RP/0/RP0/CPU0:NCS5508-Core1-DUT#sh telemetry model-driven subscription        
Thu Jan 28 16:07:21.987 GMT
Subscription:  health                   State: ACTIVE
-------------
  Sensor groups:
  Id                               Interval(ms)        State     
  health                           30000               Resolved  

  Destination Groups:
  Id                 Encoding            Transport   State   Port    Vrf     IP            
  DGroup1            self-describing-gpb grpc        Active  57000           217.46.30.20  
    No TLS            

Subscription:  optics                   State: ACTIVE
-------------
  Sensor groups:
  Id                               Interval(ms)        State     
  optics                           30000               Resolved  

  Destination Groups:
  Id                 Encoding            Transport   State   Port    Vrf     IP            
  DGroup1            self-describing-gpb grpc        Active  57000           217.46.30.20  
    No TLS            

Subscription:  interfaces               State: ACTIVE
-------------
  Sensor groups:
  Id                               Interval(ms)        State     
  interfaces                       30000               Resolved  

  Destination Groups:
  Id                 Encoding            Transport   State   Port    Vrf     IP            
  DGroup1            self-describing-gpb grpc        Active  57000           217.46.30.20  
    No TLS            

Subscription:  routing                  State: ACTIVE
-------------
  Sensor groups:
  Id                               Interval(ms)        State     
  routing                          30000               Resolved  

  Destination Groups:
  Id                 Encoding            Transport   State   Port    Vrf     IP            
  DGroup1            self-describing-gpb grpc        Active  57000           217.46.30.20  
    No TLS            

RP/0/RP0/CPU0:NCS5508-Core1-DUT#
```
## Sample Telemetry and SNMP collection

SNMP Metrics
![Alt text](/images/IOSXR_Device_Metrics_SNMP.png?raw=true "SNMP metrics collected by telegraf")


##  Stopping the telemetry stack

* Stop the telemetry stack without removing the database
```
sudo docker-compose down
```
* Stop the docker telemetry stack and remove the influxdb database iosxrtelemetrystackindocker_influxdb  

NOTE: The existing influxdb time series data will be lost.

```
sudo docker-compose down -v
```
