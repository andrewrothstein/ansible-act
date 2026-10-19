#!/usr/bin/env bash
set -e
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT
readonly MIRROR=https://github.com/nektos/act/releases/download

# https://github.com/nektos/act/releases/download/v0.2.62/checksums.txt
# https://github.com/nektos/act/releases/download/v0.2.62/act_Linux_x86_64.tar.gz

dl()
{
    local lchecksum=$1
    local ver=$2
    local os=$3
    local arch=$4
    local archive_type=${5:-tar.gz}
    local platform="${os}_${arch}"
    local file=act_${platform}.${archive_type}
    local url=$MIRROR/v$ver/$file
    printf "    # %s\n" $url
    local sum
    sum=$(grep -F -- "  $file" "$lchecksum" | awk '{print $1}')
    if ! printf '%s' "$sum" | grep -Eq '^[0-9a-f]{64}$'; then
        echo "bad or missing checksum for $file" >&2
        exit 1
    fi
    printf "    %s: sha256:%s\n" $platform $sum
}

dl_ver () {
    local ver=$1
    local checksum_url=${MIRROR}/v${ver}/checksums.txt
    printf "  # %s\n" $checksum_url
    local lchecksum=$DIR/act-${ver}-checksums.txt

    if [ ! -e $lchecksum ];
    then
        curl --proto '=https' --tlsv1.2 -sSLf -o $lchecksum $checksum_url
    fi

    printf "  '%s':\n" $ver
    dl $lchecksum $ver Darwin arm64
    dl $lchecksum $ver Darwin x86_64
    dl $lchecksum $ver Linux arm64
    dl $lchecksum $ver Linux armv6
    dl $lchecksum $ver Linux armv7
    dl $lchecksum $ver Linux i386
    dl $lchecksum $ver Linux x86_64
    dl $lchecksum $ver Windows arm64 zip
    dl $lchecksum $ver Windows i386 zip
    dl $lchecksum $ver Windows x86_64 zip
}

dl_ver ${1:-0.2.89}
