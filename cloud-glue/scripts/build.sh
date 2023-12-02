#!/usr/bin/env bash

rootdir=$(git rev-parse --show-toplevel)

LIB_PATH=$rootdir
LAMBDA_PATH=$rootdir/terraform/cloud-watch-glue/scripts
ZIP_NAME=handler.zip
ZIP_PATH=$LAMBDA_PATH/$ZIP_NAME


python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
deactivate
cd venv/lib/python3.11/site-packages/
zip -r9 $ZIP_PATH .
cd $LAMBDA_PATH
zip -g $ZIP_NAME handler.py
