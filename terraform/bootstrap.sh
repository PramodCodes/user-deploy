#!/bin/bash
# setting debug mode with -x
set -x
echo "Catalogue setup "
component=$1
envionment=$2 # dont use env here , its a reserved keyword in linux
app_version=$3 # this is the version of the application from jenkins to terraform to ansible
#  we are installign asnbile with python pip
yum install python3.11-devel python3.11-pip -y
pip3 install ansible botocore boto3 
# if ansible needs to connect to aws we need to install boto3 and botocore
# ansible pull will be used to pull the playbooks from the git repository
# ansible pull is localhost because its installing in its own machine not connecting to any other servers for installation
# we usually use ansible pull with cron job
ansible-pull -U https://github.com/PramodCodes/roboshop-ansible-roles-tf.git -e component=$component -e env=$envionment -e app_version=$app_version main-tf.yaml -vvv
