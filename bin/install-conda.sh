#!/usr/bin/env bash

#download miniconda from the official archive
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    #linux
    echo "OS detected : "$OSTYPE
    curl -o ./bin/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -s

elif [[ "$OSTYPE" == "darwin"* ]]; then
    #Mac OSX
    echo "OS detected : "$OSTYPE
    curl -o ./bin/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -s

else
    #unsupported
    echo "OS detected : "$OSTYPE
    echo "unsupported OS version... exiting installation"
    exit
fi

# install
# -b for silent install with default options
# -u for updating an existing installation
bash ./bin/miniconda.sh -b -u

# delete unwanted files
rm /bin/miniconda.sh