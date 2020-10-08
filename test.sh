#!/bin/bash
set -euxo pipefail

function cleanup {
	kill $gotify_pid
	echo killed $gotify_pid
}
trap cleanup EXIT

resource_dir=${1:-.}
dir=$(mktemp -d)
if test -f gotify-linux-amd64.zip
then
	cp gotify-linux-amd64.zip $dir/gotify-linux-amd64.zip
else
	curl --silent -L https://github.com/gotify/server/releases/download/v2.0.20/gotify-linux-amd64.zip --output $dir/gotify-linux-amd64.zip
fi
unzip -d $dir $dir/gotify-linux-amd64.zip >/dev/null

export GOTIFY_SERVER_SSL_ENABLED=false
export GOTIFY_SERVER_LISTENADDR=localhost
export GOTIFY_SERVER_PORT=8088
export GOTIFY_DEFAULTUSER_NAME=admin
export GOTIFY_DEFAULTUSER_PASS=admin
export GOTIFY_DATABASE_DIALECT=sqlite3
export GOTIFY_DATABASE_CONNECTION=$(mktemp)
export GOTIFY_UPLOADEDIMAGESDIR=$(mktemp -d)
export GOTIFY_PLUGINSDIR=$GOTIFY_UPLOADEDIMAGESDIR

$dir/gotify-linux-amd64 >/dev/null&
gotify_pid="$!"

sleep 2;
app_token=$(curl --silent --user admin:admin \
	"http://$GOTIFY_SERVER_LISTENADDR:$GOTIFY_SERVER_PORT/application" \
	-F description=test-app-for-ci \
	-F name=test-app | jq -r '.token')

payload='{"source":{"appToken":"'${app_token}'","url":"http://localhost:8088"}, "params":{"message":"test-message", "title":"test-title","priority":5}}'

response=$(echo $payload | bash "${resource_dir}/out" $(mktemp -d) 2>/dev/null)

function check_is_equal {
	if [ $# != 3 ]
	then
		return 1
	fi
	from_json=$(echo $1 | jq -r "$2")
	[ "$3" = "$from_json" ] && return 0 || return 1
}

function check_is_date {
	if [ $# != 2 ]
	then
		return 1
	fi
	from_json=$(echo $1 | jq -r "$2")
	date -d $from_json >/dev/null && return 0 || return 1
}

errors=()
check_is_date  "$response" '.version.date' || errors+=("version.date")
check_is_equal "$response" '.version.id' 1 || errors+=("version.id")
check_is_equal "$response" '.version.message' "test-message" || errors+=("version.message")
check_is_equal "$response" '.version.title' "test-title" || errors+=("version.title")
check_is_equal "$response" '.metadata[0].name' "url" || errors+=('.metadata[0].name')
check_is_equal "$response" '.metadata[0].value' "http://localhost:8088" || errors+=('.metadata[0].value')
check_is_equal "$response" '.metadata[1].name' "title" || errors+=('.metadata[1].name')
check_is_equal "$response" '.metadata[1].value' "test-title" || errors+=('.metadata[1].value')
check_is_equal "$response" '.metadata[2].name' "message" || errors+=('.metadata[2].name')
check_is_equal "$response" '.metadata[2].value' "test-message" || errors+=('.metadata[2].value')

if [ ${#errors[@]} -eq 0 ]; then
	echo "No errors found"
	exit 0
else
	echo "Errors in:"
	echo "$errors"
	echo "response: $response"
	exit 1
fi
