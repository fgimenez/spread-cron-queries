#!/bin/sh
set -eu

arch="${1:-amd64}"
channel="${2:-edge}"
branch="kernel-${arch}-${channel}"

after_number=
last_success_revision=

while [ -z "$last_success_revision" ]; do
    url=https://api.travis-ci.org/repos/snapcore/spread-cron/builds
    if [ -n "$after_number" ]; then
        url="${url}?after_number=${after_number}"
    fi
    last_success_message=$(curl -s "$url" | jq -j 'map(select(.result == 0) | select(.branch == "'${branch}'")) | .[0].message')
    if [ "$last_success_message" != null ]; then
        last_success_revision=$(echo "$last_success_message" | sed  -n "s|^.*(\(.*\))$|\1|p")
        if [ -n "$last_success_revision" ]; then
            echo "$last_success_revision"
            exit 0
        fi
    fi
    after_number=$(curl -s "$url" | jq -j '.[-1].number')
    if [ "$after_number" -lt "25" ]; then
        echo "No successful executions found for ${branch}"
        exit 1
    fi
done
