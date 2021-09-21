# Update Nginx config from Consul using consul-template

#### Overview

##### Prerequisites
Consul and Consul-template installed
nginx installed and configred to run in any manner.

##### Motivation
The desire to move traffic smoothly, and safely, from  one upstream to another without downtime and incrementally.
I've used this many times to move from VM's to Kubernetes, or one k8s cluster to another.
We've used this as a kill-switch to dev-null traffic during emergencies, and more importantly to re-introduce traffic slowly to avoid a traffic stampede herd.
Most of the time this sits unused, but when needed it's instrumental and vital.

## Files and purpose

#### _etc_nginx_nginx.conf :
  The pre-conul-templated version of the nginx config.
  Lives in /opt/consul/templates/template/ and is formatted as full path to file, '/' replaced with '_'
  This Nginx config is not complete. It's just enough to copy-paste into an existing config, then rename as the underscored path.
  

#### consul_watch.json :
  Json configuration consul.
  Says "watch this key" then "run this file"
  Reuqires consul, and consul-template be installed.

#### update_template.sh
  This is a shell script which does the work for consul to write the file and change mode and perms.
  Valuable middle-ware. Author has been lost to time. But I would like to send them cookies for how much use this has seen without issue.
  
  
