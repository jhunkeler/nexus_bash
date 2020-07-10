#!/bin/bash
#
# Nexus RAW repository interface
#


# Check existence of upstream file or directory
# @param url: path relative to NEXUS_URL (i.e. "repository/my_data", "repository/my_data/file.txt")
# @return non-zero indicates failure
nexus_raw_provides() {
    local url
    local response

    url="${NEXUS_URL}/$1"
    if [[ -z $url ]]; then
        echo "nexus_raw_provides: requires a path relative to $NEXUS_URL" >&2
        return 1
    fi

    response=$(curl -s --head "$url" | head -n 1 | awk '{print $2}')
    if (( $response != 200 )); then
        return 1
    fi
    return 0
}

# Download a file
# @param url:
# @param filename:
# @param dest:
# @return
#   1: path to file
#   2: non-zero indicates failure
nexus_raw_download() {
    local url
    local filename
    local dest

    url="${NEXUS_URL}/$1"
    if [[ -z $url ]]; then
        echo "nexus_raw_download: requires a path relative to $NEXUS_URL" >&2
        return 1
    fi

    filename=$(basename $url)
    if ! nexus_raw_provides "$1"; then
        echo "${url}: not found on remote server" >&2
        return 1
    fi

    dest="$2"
    if [[ -z "${dest}" ]]; then
        dest="."
    elif [[ ! -d "${dest}" ]]; then
        mkdir -p "${dest}"
    fi

    if ! curl -L "$url" > "${dest}/${filename}"; then
        echo "Could not download data" >&2
        return 1
    fi

    echo "$dest/$filename"
    return 0
}

# Upload a file
# @param url: path relative to NEXUS_URL (i.e. "repository/my_data")
# @param filename: local file to upload
# @return non-zero indicates failure
nexus_raw_upload() {
    local url
    local filename

    url="${NEXUS_URL}/$2"
    filename="$1"

    if [[ -z $url ]]; then
        echo "nexus_raw_upload: requires a path relative to $NEXUS_URL" >&2
        return 1
    fi

    if (( NEXUS_BASH_VERBOSE )); then
        /bin/echo -n "Uploading '$filename' => '${2}'... "
    fi
    if ! curl -s --user "${NEXUS_AUTH}" --upload-file "${filename}" "${url}/${filename}"; then
        if (( NEXUS_BASH_VERBOSE )); then
            echo "Failed" >&2
        fi
        return 1
    fi

    if (( NEXUS_BASH_VERBOSE )); then
        echo "done"
    fi
    return 0
}

# Upload a directory tree
# @param src: path to local directory
# @param dest: path relative to NEXUS_URL (i.e. "repository/my_data")
# @return non-zero indicates failure
nexus_raw_upload_dir() {
    local src
    local dest
    local status_callback
    src="$1"
    dest="$2"

    if [[ ! -d "$src" ]]; then
        echo "nexus_raw_upload_dir: source directory does not exist: ${src}" >&2
        return 1
    fi

    if [[ -z "$dest" ]]; then
        echo "nexus_raw_upload_dir: requires a destination relative to ${NEXUS_URL}" >&2
        return 1
    fi

    local failures
    local paths
    paths=($(find "${src}" -type f -print))

    failures=0
    for (( i=0; i < ${#paths[@]}; i++ )); do
        local retval
        local f
        f="${paths[$i]}"

        if ! nexus_raw_upload "$f" "$dest"; then
            (( failures++ ))
        fi
    done

    if (( failures )); then
        return 1
    fi
    return 0
}
