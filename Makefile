include config.mk
SHELL := /bin/bash

# Add conda to the path
PATH := $(PATH):$(HOME)/miniconda3/condabin

# This is needed so that conda can be executed from whithin a shell script
SOURCE=source $$(conda info --base)/etc/profile.d/conda.sh

# Command to create conda environment
CREATE=$(source) ; conda create -y --name $(APP_NAME) python=3.7 openjdk=8

# Command to create conda environment for test
CREATE_TEST_ENV=$(source) ; conda create -y --name $(APP_NAME)-test python=3.7 openjdk=8

# Command to activate conda enviroment
ACTIVATE=$(source) ; conda activate $(APP_NAME)

# Command to activate conda test envirnment
ACTIVATE_TEST=$(source) ; conda activate $(APP_NAME)-test

help:
@echo "install-conda - onetime activity to install conda"
@echo "clean install - setup your local env for development"
@echo "all - check for lint , install requirement and build artifacts (ready for deployment)"
@echo "safe-execute - builds and displays commands to execute from build-output"
@echo "execute - displays commands for light weight execution"
@echo "deploy-stg - build and deploys to staging"
@echo "deploy - build and deploys to production"
 
# one time activity
install-conda:
./bin/install-conda.sh
 
# one time activity, only if you add a new package
compile:
($(ACTIVATE) ; pip install --upgrade setuptools)
($(ACTIVATE) ; pip install --upgrade wheel)
($(ACTIVATE) ; pip install --upgrade pip-compile-multi)
($(ACTIVATE) ; pip install --upgrade pip-tools)
($(ACTIVATE) ; pip-compile-multi)
 
clean-conda:
($(SOURCE) ; conda deactivate)
($(SOURCE) ; conda env remove --name $(APP_NAME) $(APP_NAME)-test)
($(CREATE))
($(ACTIVATE) ; pip install -U databricks-connect)
 
clean-conda-test:
($(SOURCE) ; conda deactivate)
($(SOURCE) ; conda env remove --name $(APP_NAME)-test)
($(CREATE_TEST_ENV))
($(ACTIVATE_TEST) ; pip install pyspark==3.0.0 mock==4.0.2 pytest==5.4.3 pytest-cov==2.9.0 hjson==3.0.2 boto3==1.17.10 pandas==1.2.2)
 
clean-meta:
rm -rf src/metastore_db
rm -rf metastore_db
rm -rf src/derby.log
rm -rf derby.log
 
clean-build:
rm -fr build-output/
 
clean-pyc:
find . -name '*.pyc' -exec rm -f {} +
find . -name '*.pyo' -exec rm -f {} +
find . -name '*~' -exec rm -f {} +
find . -name '__pycache__' -exec rm -fr {} +
 
clean-test:
@echo "Placeholder : Clean test artifacts"
 
clean: clean-build clean-pyc clean-test clean-meta
 
install:
@echo $(PIP_INDEX_URL)
($(CREATE))
($(ACTIVATE) ; pip install -r requirements/requirements.txt)
 
build: clean compile install lint
mkdir -p ./build-output/cluster_init_scripts
cp submit.py execute.py ./build-output
zip -r ./build-output/src.zip src
for file in cluster_init_scripts/*; do envsubst < "$$file" > "./build-output/$$file"; done
 
all: build
@echo "###############################################################################################################################"
@echo "WARNING: Run 'make compile' if you have changed any libraries and rerun 'make all'."
@echo "WARNING: Run 'conda deactivate' and then 'make clean-conda' if you have installed conda libraries without using 'make install'"
@echo "###############################################################################################################################"
safe-execute: build
@echo "####################################################################################################################################"
@echo "Run the following commands"
@echo "cd build-output"
@echo "source activate.sh"
@echo "Example: spark-submit execute.py --job template --job-args \"env='local',foo='bar'\""
@echo "Example: spark-submit execute.py --job web_event --job-args \"date='2020-05-05',anonymous_id='7ead89dc-2dd4-40cc-916f-c62f0d4c52ca'\""
@echo "####################################################################################################################################"
 
execute:
@echo "Run the following commands"
@echo "source activate.sh"
@echo "Example: spark-submit execute.py --job template --job-args \"env='local',foo='bar'\""
@echo "Example: spark-submit execute.py --job web_event --job-args \"date='2020-05-05',anonymous_id='7ead89dc-2dd4-40cc-916f-c62f0d4c52ca'\""
 
format:
($(ACTIVATE); autopep8 -r src/ --in-place)
($(ACTIVATE); autopep8 -r test/ --in-place)
($(ACTIVATE); isort -rc src/)
($(ACTIVATE); isort -rc test/)
 
deploy: install-conda build
@echo "Deploying to location $(PROD_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/"
aws s3 rm $(PROD_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
aws s3 cp build-output/ $(PROD_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
 
deploy-stg: install-conda build
@echo "Deploying to location $(STG_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/"
aws s3 rm $(STG_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
aws s3 cp build-output/ $(STG_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
 
deploy-dev: install-conda build
@echo "Deploying to location $(DEV_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/"
#aws s3 rm $(DEV_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
aws s3 cp build-output/ $(DEV_DEPLOYMENT_BUCKET)/deploy/$(APP_NAME)/ --recursive
 
tests:
($(ACTIVATE_TEST) ; ./bin/unit-test.sh $(filter-out $@,$(MAKECMDGOALS)))
 
lint:
($(ACTIVATE) ; ./bin/lint.sh)
 
submit: # usage: make submit job_name="dim_person"
($(ACTIVATE) ; python3 submit.py --job ${job_name})
 
update-lineage:
($(ACTIVATE) ; python3 src/lineage/update_lineage.py)