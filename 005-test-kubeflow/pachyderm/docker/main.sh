#!/usr/bin/env sh

# Input:
#     --params  Json parameters folder
#     --data    Input  folder
#     --output  Output folder

# Just incase istio is slow.
while ! ping -c 1 www.google.com; do
    sleep 2
done

# Get the source
if ! git clone --depth=1 \
    https://github.com/kennethchu-statcan/covid19/ \
    /tmp/covid19; then
    echo "Couldn't git clone. Exiting. Network Error?"
    exit 1
fi
mv /tmp/covid19/005-test-kubeflow/pipeline-test/image-loadData/src /src

while test -n "$1"; do
    case "$1" in
        --data)
            shift
            DATA="$1"
            ;;

        --output)
            shift
            OUTPUT="$1"
            ;;

        --params)
            shift
            JSON_FOLDER="$1"
            ;;

        *)
            echo "Invalid option $1; allowed: --data --params --options" >&2
            exit 1
            ;;
    esac
    shift
done

#############
# This is where the single-run modelling R command can go ... ?
#############

# IMPORTANT! /pfs/ filesystem uses symlinks
# So need -L in the find command.
paramsFILE=$(find -L "$JSON_FOLDER" -type f | sed 1q)

ERROR_CHECK_THIS=$(find -L "$JSON_FOLDER" -type f | wc -l)
if ! test $ERROR_CHECK_THIS = 1; then
    echo "Wrong number of parameters?!?!" >&2
    find -L "$JSON_FOLDER" -type f >&2
    echo "There should be one file." >&2
    exit 1
fi

  dataDIR="$DATA"
  codeDIR=/src
outputDIR=/output

 myRscript=${codeDIR}/main-pachyderm.R
stdoutFile=${outputDIR}/stdout.R.`basename ${myRscript} .R`
stderrFile=${outputDIR}/stderr.R.`basename ${myRscript} .R`
R --no-save --args ${dataDIR} ${paramsFILE} ${codeDIR} ${outputDIR} < ${myRscript} > ${stdoutFile} 2> ${stderrFile}

echo 'R finished.'
