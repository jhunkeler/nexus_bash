#!/bin/bash
#
# Global Variables
#
NEXUS_BASH_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NEXUS_BASH_INTERFACE_ROOT="${NEXUS_BASH_ROOT}/interface.d"

#
# Global Arguments
#
# NEXUS_URL: str
#   HTTP[S] address of the Nexus server
#   e.g. NEXUS_URL="https://nexus.server.tld"
#
NEXUS_URL=${NEXUS_URL:-}

# NEXUS_AUTH: str
#   Provide user credentials to the Nexus server. Username and password are delimited by ':'
#   e.g. NEXUS_AUTH="username:password"
NEXUS_AUTH=${NEXUS_AUTH:-}

# NEXUS_BASH_VERBOSE: int
#   Toggle verbose output mode
#   e.g. NEXUS_BASH_VERBOSE=1
NEXUS_BASH_VERBOSE=${NEXUS_BASH_VERBOSE:-0}

#
# Common Functions
#

# Check NEXUS_URL is a valid Nexus server
# @return non-zero indicates failure
nexus_available() {
    response=$(curl --head -X GET "$NEXUS_URL/service/rest/v1/status" | head -n 1 | awk '{print $2}')
    if (( $response != 200 )); then
        return 1
    fi
    return 0
}

# Populate interfaces
for iface in $(find "${NEXUS_BASH_INTERFACE_ROOT}" -type f -name '*.sh'); do
    source "$iface"
done

nexus_json_begin() {
    python -c "import json, sys; data=json.load(sys.stdin); $*"
}

nexus_json_len() {
    nexus_json_begin "print(len(data))"
}

nexus_json_value() {
    nexus_json_begin "dict(data[$1]).get('$2', '')"
}

nexus_json_pairs() {
    if (( $# == 1 )); then
        nexus_json_begin "[print('{}=\'{}\''.format(k, v)) for (k, v) in dict(data[$1]).items() if k != 'attributes']"
    fi
}
