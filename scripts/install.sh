#!/bin/bash

# Script Name: install.sh
# Author: Greg Oliver - Microsoft github:(sebastus)
# Version: 0.1
# Last Modified By: Greg Oliver
# Description:
#  This script configures authentication for Terraform and remote state for Terraform.
# Parameters :
#  1 - s: Azure subscription ID
#  2 - a: Storage account name
#  3 - k: Storage account key (password)
#  4 - l: MSI client id (principal id)
#  5 - u: User account name
#  6 - h: help
# Note : 
# This script has only been tested on Ubuntu 12.04 LTS & 14.04 LTS and must be root

set -e

help()
{
    echo "This script sets up a node, and configures pre-installed Splunk Enterprise"
    echo "Usage: "
    echo "Parameters:"
    echo "- s: Azure subscription ID"
    echo "- a: Storage account name"
    echo "- k: Storage account key (password)"
    echo "- l: MSI client id (principal id)"
    echo "- u: User account name"
    echo "- h: help"
}

# Log method to control log output
log()
{
    echo "`date`: $1"
}

# You must be root to run this script
if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

# Arguments
while getopts :s:a:k:l:u: optname; do
  if [[ $optname != 'e' && $optname != 'k' ]]; then
    log "Option $optname set with value ${OPTARG}"
  fi
  case $optname in
    s) #azure subscription id
      SUBSCRIPTION_ID=${OPTARG}
      ;;
    a) #storage account name
      STORAGE_ACCOUNT_NAME=${OPTARG}
      ;;
    k) #storage account key
      STORAGE_ACCOUNT_KEY=${OPTARG}
      ;;
    l) #PrincipalId of the MSI identity
      MSI_PRINCIPAL_ID=${OPTARG}
      ;;
    u) #user account name
      USERNAME=${OPTARG}
      ;;
    h) #Show help
      help
      exit 2
      ;;
    \?) #Unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      help
      exit 2
      ;;
  esac
done

TEMPLATEFOLDER = "/home/$USERNAME/tfTemplate"
REMOTESTATEFILE = "$TEMPLATEFOLDER/remoteState.tf"
ACCESSKEYFILE = "/home/$USERNAME/access_key"
TFENVFILE = "/home/$USERNAME/tfEnv.sh"

mkdir $TEMPLATEFOLDER

cp ./azureProviderAndCreds.tf /home/tfuser/tfTemplate
chmod 666 /home/tfuser/tfTemplate/azureProviderAndCreds.tf 

touch $REMOTESTATEFILE
echo "terraform {"                                          >> $REMOTESTATEFILE
echo " backend \"azurerm\" {"                               >> $REMOTESTATEFILE
echo "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""   >> $REMOTESTATEFILE
echo "  container_name       = \"terraform-state\""         >> $REMOTESTATEFILE
echo "  key                  = \"prod.terraform.tfstate\""  >> $REMOTESTATEFILE
echo "  }"                                                  >> $REMOTESTATEFILE
echo "}"                                                    >> $REMOTESTATEFILE
chmod 666 $REMOTESTATEFILE

chown -R tfuser:tfuser /home/tfuser/tfTemplate

touch $ACCESSKEYFILE
echo "access_key = \"$STORAGE_ACCOUNT_KEY\""                >> $ACCESSKEYFILE
chmod 666 $ACCESSKEYFILE
chown tfuser:tfuser $ACCESSKEYFILE

touch $TFENVFILE
echo "export ARM_SUBSCRIPTION_ID =\"$SUBSCRIPTION_ID\""     >> $TFENVFILE
echo "export ARM_CLIENT_ID       =\"$MSI_PRINCIPAL_ID\""    >> $TFENVFILE
chmod 755 $TFENVFILE
chown tfuser:tfuser $TFENVFILE

# create the container for remote state
#az login --service-principal --tenant $TENANT_ID -u $CLIENT_ID -p $CLIENT_SECRET
#az storage container create -n terraform-state --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY
