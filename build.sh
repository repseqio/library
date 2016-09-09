#!/bin/bash

# Linux readlink -f alternative for Mac OS X
function readlinkUniversal() {
    targetFile=$1

    cd `dirname $targetFile`
    targetFile=`basename $targetFile`

    # iterate down a (possible) chain of symlinks
    while [ -L "$targetFile" ]
    do
        targetFile=`readlink $targetFile`
        cd `dirname $targetFile`
        targetFile=`basename $targetFile`
    done

    # compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    phys_dir=`pwd -P`
    result=$phys_dir/$targetFile
    echo $result
}

os=`uname`
delta=100

dir=""

case $os in
    Darwin)
        dir=$(dirname "$(readlinkUniversal "$0")")
    ;;
    Linux)
        dir="$(dirname "$(readlink -f "$0")")"
    ;;
    *)
       echo "Unknown OS."
       exit 1
    ;;
esac

cd ${dir}

buildFolder="${dir}/build"

mkdir -p ${buildFolder}

tomerge=()

for f in $(find . -type f -name "*.json" -not -path "./.git*" -not -path "./build*");
do
    out=${buildFolder}/${f}.compiled
    mkdir -p $(dirname ${out})
    repseqio compile -f ${f} ${out}
    tomerge+=("${out}")
done

tag=$(git describe --always --tags)

repseqio merge -f ${tomerge[@]} ${dir}/repseqio.${tag}.json.gz


