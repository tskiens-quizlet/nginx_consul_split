# Update Nginx config from Consul using consul-template

## Files and purpose

### nginx-snippet.conf :
  The pre-conul-templated version of the nginx config.
  Lives in /opt/consul/templates/template/ and is formatted as full path to file, '/' replaced with '_'
  e Nginx config, not complete. Just enough to declare the upstreams and the split and maps.

### consul_watch.json :
  Json configuration consul.
  Says "watch this key" then "run this file"
  Reuqires consul, and consul-template be installed.

### update_template.sh
  This is a shell script which does the work for consul to write the file and change mode and perms.
  Valuable middle-ware. Author has been lost to time. But I would like to send them cookies for how much use this has seen without issue.
