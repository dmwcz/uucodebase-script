#!/bin/bash

# author Milan Martinek
#        6-138-1@unicorn.com
# up-to-date source at https://github.com/dmwcz/uucodebase-script

# defaults
DEFAULT_SSH_PATH="${HOME}/.ssh" # point to path where you want create ssh key. Default is ~/.ssh
REPOSITORY_URI="codebase.plus4u.net"
EMAIL_DOMAIN="@plus4u.net"

# helpers
trim_whitespace() {
  echo "${1}" | sed '/^$/d'
}

remove_existing_file() {
  rm "${file_path}"
  rm "${file_path}.pub"
  echo "Removed file ${file_path}"
}

append_config() {
  echo "Host ${REPOSITORY_URI}" >>$config_path
  echo "Hostname ${REPOSITORY_URI}" >>$config_path
  echo "IdentityFile ${file_path}" >>$config_path
  echo "" >>$config_path # just an empty line
}

show_help() {
  echo "USAGE codebase.sh [OPTIONS]... UID
Create ssh key pair for uuCodebase for given UID.
E.g 'codebase.sh 1-1' will create key pair for uuIdentity 1-1

Possible arguments
  -o, --overwrite     overwrites existing keys with new ones without asking
  -c, --create-only   only creates key pair and sets config. It skips uploading to uuCodebase
  -p, --path PATH     specify path where to create key pair. Default values is ~/.ssh
  -h, --help          shows some help text
  "
}

# read parameters
while [[ $# -gt 0 ]]; do
  case $1 in
  -p | --path)
    ssh_path="$2"
    shift
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  -o | --overwrite)
    overwrite_existing=YES
    shift
    ;;
  -c | --create-only)
    create_only=YES
    shift
    ;;
  *) # unknown option
    uid="$(trim_whitespace $1)"
    shift
    ;;
  esac
done

# check passed configuration
if [[ ! "$uid" =~ ^([0-9]+-){1,3}1$ ]]; then
  echo "Provided invalid format of UID '${uid}'"
  show_help
  exit 1
fi
if [ -z "${ssh_path}" ]; then
  ssh_path=$DEFAULT_SSH_PATH
  # ensure default directory
  mkdir -p $ssh_path
else
  if [ ! -d "${ssh_path}" ]; then
    echo "Given path '${ssh_path}' does not exist!"
    show_help
    exit 1
  fi
fi

# check for existing file
generate_file=YES
file_path="${ssh_path}/${uid}"
if [ -f $file_path ]; then
  # ask if file should be rewritten
  if [ -z "${overwrite_existing}" ]; then
    read -p "File ${file_path} already exists, do you want to overwrite it? (y/N): " overwrite_prompt
    if [[ $overwrite_prompt == "y" ]]; then
      remove_existing_file
    else
      generate_file=NO
      echo "Keeping file ${file_path}"
    fi
  else
    remove_existing_file
  fi
fi

# generate key with comment and name as given uid
if [[ $generate_file == "YES" ]]; then
  ssh-keygen -q -t rsa -b 4096 -N "" -C "${uid}${EMAIL_DOMAIN}" -f $file_path
  echo "Generated new key pair ${file_path}"
fi

# required by unix systems, should be ok for windows as well
chmod 600 $file_path

# update config file
config_path="${ssh_path}/config"

# check if exists
if [ ! -f "${config_path}" ]; then
  touch $config_path
  echo "Created config file"
fi

# check if codebase records exists
if grep -q "${REPOSITORY_URI}" "${config_path}"; then
  # modify existing record
  config_path_altered="${config_path}_new"
  should_replace=NO
  # line by line to find the IdentityFile for codebase rule
  while IFS= read -r line; do
    case "$line" in
    Hostname*)
      if [[ $line == *"${REPOSITORY_URI}"* ]]; then
        should_replace=YES
      fi
      echo "${line}" >>$config_path_altered
      ;;
    IdentityFile*)
      if [[ $should_replace == "YES" ]]; then
        echo "IdentityFile ${file_path}" >>$config_path_altered
        should_replace=NO
      else
        echo "${line}" >>$config_path_altered
      fi
      ;;
    *) echo "${line}" >>$config_path_altered ;;
    esac
  done <$config_path
  # replace original config
  rm $config_path
  mv $config_path_altered $config_path
else
  # just append to the file
  append_config
fi
echo "Config file updated"

if [[ $create_only == "YES" ]]; then
  echo "Script executed with create-only flag"
  exit 0
fi

# ask for user passwords for uu
read -sp 'Access Code 1: ' acc1
echo ""; # just some formatting
read -sp 'Access Code 2: ' acc2
echo ""; # just some formatting

# curl public key into codebase
public_key=$(<"${file_path}.pub")

body_start='{
	"TXTA_KEY": {
		"id": "bfe5f82753c50b921956856151266ad7de-7fbc",
		"code": "TXTA_KEY",
		"name": "text area",
		"width": 350,
		"height": 51,
		"required": false,
		"disabled": false,
		"readOnly": false,
		"maxLength": 2000,
		"value": "'
body_end='",
		"componentType": "uu.os.form.textarea"
	},
	"uuView": {
		"sourceComponent": "bfe5f82753c50b928f188b1522d5eb74d-7fee"
	},
	"schemaUri": "ues:SYSTEM:UU.OS.VUC/REQUEST_MESSAGE-SCHEMA-V3"
}'

curl --request POST -s -S \
  --url 'https://vuc.plus4u.net/78462435/plus4u-codebase/Security/setSSHKey/submit?uuUri=ues%3AUU-BT%5B78462435%5D%3APLUS4U.CODEBASE%2FCONTROL_PANEL%5B44191586043257909%5D%3A' \
  --user ${acc1}:${acc2} \
  --header 'content-type: application/json' \
  --data "${body_start}${public_key}${body_end}"