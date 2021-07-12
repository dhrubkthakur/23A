#!/usr/bin/env bash
# step 0 - Initialize the working directory with everything you need to build and run things

# fail on any error
set -e

SERVICE_NAME="23A"
PIP_CONF="build-output/pip.conf"

# create build output directory
mkdir -p build-output

# check if script is being sourced
# if not, show all commands
[[ "$0" = "$BASH_SOURCE" ]] && set -x

cd "$(dirname "${BASH_SOURCE[0]}")/.."
#source ./bin/common-export.sh

# check for local pip.conf
# if it does not exist, create one
# add pip.conf to the directory
if [[ -f $HOME/.config/pip/pip.conf ]]; then

cp $HOME/.config/pip/pip.conf ${PIP_CONF}

elif [[ -f /etc/pip.conf ]]; then
cp /etc/pip.conf ${PIP_CONF}

else
cat << EOF > ${PIP_CONF} 
EOF

cp /etc/pip.conf ${PIP_CONF}

mkdir -p $HOME/.config/pip
cp ${PIP_CONF} $HOME/.config/pip/pip.conf

fi

# create virtualenv
if [[ ! -d .ve ]]; then
    python3 -m venv .ve --prompt="(${SERVICE_NAME})"
fi

# activate the virtualenv
source .ve/bin/activate

# make sure we've upgraded out pip
pip install --upgrade pip wheel

# install packages into virtualenv 
pip install --upgrade pip
pip install --upgrade pip-tools
pip-sync requirements/requirements.txt
