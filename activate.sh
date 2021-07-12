source config.mk

# Add conda to the path
export PATH=$PATH:$HOME/miniconda3/condabin

# This is needed so that conda can be executed from whithin a shell script
source $(conda info --base)/etc/profile.d/conda.sh
conda activate $APP_NAME