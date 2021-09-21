#!/bin/bash

# A wrapper script for the consul-template command
# updates owner and permissions
# optionally runs a lint command and a refresh command

set -euo pipefail

ESCAPED_FILENAME="$1"
FILE_PATH="$2"
OWNER="$3"
GROUP="$4"
MODE="$5"
REFRESH_COMMAND="$6"
LINT_COMMAND="$7"
RUN_SOURCE="$8"

CONSUL_IP=${ $CONSUL_IP } : 10.11.12.13 } # this allows use of env_variable or default
CONSUL_PORT=8500

if [[ "$(whoami)" != "root" ]]; then
	echo "Must be run as root" 1>&2
	exit 1
fi

TEMPLATE_FILE="/opt/consul/templates/template/$ESCAPED_FILENAME.tmpl"

NOW=$(date +%s%N)

STAGING_FILE="/opt/consul/templates/staging/$ESCAPED_FILENAME.$NOW"
LOG_FILE="/var/log/consul/templates/$ESCAPED_FILENAME.$NOW"

RESULT_KEY="template_results/$HOSTNAME/$ESCAPED_FILENAME"

function tag_log() {
	echo "$(date) $@" | tee -a $LOG_FILE
}

tag_log "$RUN_SOURCE"

tag_log 'start'

JSON_INPUT="$(cat)"

# might want to delete this if too much data getting written to log
# currently looks like only changing keys and metadata get recorded here
tag_log 'pre JSON_INPUT'
echo "$JSON_INPUT" | tee -a $LOG_FILE
tag_log 'post JSON_INPUT'

DATA_VERSION="0"
if [[ -z "$JSON_INPUT" || "$JSON_INPUT" == 'null' ]]; then
	echo "No data yet in Consul for prefix, trying to generate template anyways"
else
	# Always an array because the watch is set on a prefix, not a specific key
	CHANGED_KEY_COUNT="$(echo $JSON_INPUT | /usr/bin/jq length)"

	# If multiple keys changed, take the highest version
	for INDEX in `seq 0 $(($CHANGED_KEY_COUNT - 1))`; do
		KEY_VERSION="$(echo $JSON_INPUT | /usr/bin/jq .[$INDEX].ModifyIndex)"
		if [[ "$KEY_VERSION" -gt "$DATA_VERSION" ]]; then
			DATA_VERSION="$KEY_VERSION"
		fi
	done

	if [[ "$DATA_VERSION" == "0" ]]; then
		echo "Unable to extract modify index from input: $JSON_INPUT" 1>&2
		exit 1
	fi
fi

function report_success_to_consul() {
	/usr/bin/consulate --api-host "$CONSUL_IP" --api-port "$CONSUL_PORT" kv set "$RESULT_KEY" "{\"success\": true, \"version\":$DATA_VERSION}" 2>&1
}

/usr/local/bin/consul-template -consul "$CONSUL_IP":"$CONSUL_PORT" -template $TEMPLATE_FILE:$STAGING_FILE -once -max-stale 0s 2>&1

FILE_DIFF=$(diff $STAGING_FILE $FILE_PATH 2>&1 || true)

if [[ -z "$FILE_DIFF" ]]; then
	tag_log 'no_diff'
	rm $STAGING_FILE
	report_success_to_consul
	exit 0
fi

tag_log 'pre FILE_DIFF'
echo "$FILE_DIFF" | tee -a $LOG_FILE
tag_log 'post FILE_DIFF'

chown -f $OWNER:$GROUP $STAGING_FILE
chmod -f $MODE $STAGING_FILE
if [[ "$LINT_COMMAND" != "none" ]]; then
	$LINT_COMMAND $STAGING_FILE
fi
mv -f $STAGING_FILE $FILE_PATH

tag_log 'moved'

if [[ "$REFRESH_COMMAND" != "none" ]]; then
	$REFRESH_COMMAND
	tag_log 'refreshed'
fi

report_success_to_consul

tag_log 'done'
