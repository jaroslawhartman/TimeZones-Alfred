#!/usr/bin/env bash

function migratePreferece() {
	LEGACY_TZPREFS="$HOME/Library/Application Support/Alfred 3/Workflow Data/carlosnz.timezones"
	[[ ! -d  "$TZPREFS" ]] && mkdir -p "$TZPREFS" 2>/dev/null
	[[ ! -e "$timezone_file" ]] && cp "$LEGACY_TZPREFS/"* "$TZPREFS/" 2>/dev/null
	[[ -e "$TZPREFS/config-1-5" ]] && rm "$TZPREFS/config-1-5" 2>/dev/null
}

function storePreference() {
   NAME="$1"
   VALUE="$2"
   
   grep -v "${NAME}|" "${CONFIG_EXTRA}" > /tmp/timezone.tmp
   
   echo "${NAME}|${VALUE}" >> /tmp/timezone.tmp
   
   cat /tmp/timezone.tmp > "${CONFIG_EXTRA}"
}

function getPreference() {
   NAME=$1
   DEFAULT=$2

   VALUE=$(grep "${NAME}|" "${CONFIG_EXTRA}" | awk -F"|" '{print $2}')
   
   VALUE=${VALUE:-"$DEFAULT"}
   echo "$VALUE"
}

#Working Directories
#includes for TimeZones scripts
TZPREFS="$alfred_workflow_data"
CONFIG_EXTRA="$TZPREFS/configExtra"
TIMEZONE_PATH="$(getPreference 'TIMEZONE_PATH' "$TZPREFS" )"

#Load path to the user's timezones.txt file.
timezone_file="$TIMEZONE_PATH/timezones.txt"

# echo "$TIMEZONE_PATH" >> /tmp/bzz
# ls -l "$TIMEZONE_PATH" >> /tmp/bzz

#Enable aliases for this script
shopt -s expand_aliases

#Case-insensitive matching
shopt -s nocasematch

migratePreferece

#Does the file actually exist?
if [ ! -e "$timezone_file" ]; then
	#If not, recreate it from defaults
	cp default_timezones.txt "$timezone_file"
fi

if ! grep 'Version2.0' "$timezone_file" > /dev/null
then
	cp default_timezones.txt "$timezone_file"
fi


# Create an empty file (extra configuration) if it does not exist

if [[ ! -e "${CONFIG_EXTRA}"  ]]; then
	touch "${CONFIG_EXTRA}"
fi

#
# Preferences section
# 
# 

TIME_FORMAT=$(getPreference "TIME_FORMAT" "24h" )
SORTING=$(getPreference "SORTING" "y" )
