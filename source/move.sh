#!/bin/bash

source includes.sh

#Ask for folder (via Applescript GUI)
user_path=$(osascript <<-EOF

tell application "System Events"
	activate
	set folderName to POSIX path of (choose folder with prompt "Choose location for your stored Timezones list")
end tell

EOF)

if [[ -z "${user_path}" ]]; then
	exit
fi

yes_no="override"

# Check if timezones.txt exists in the target
# Ask if override
if [[ -e "${user_path}/timezones.txt" ]]
then
	yes_no=$(osascript <<-EOF
	tell application "System Events"
		activate
		display alert "A timezones.txt exists in the new location.\nUse config from the new location or override it by the current config?" buttons {"New location", "Override"}

		if button returned of result = "Override" then
			return "override" 
		end if
	end tell
	EOF)
fi

if [[ "$yes_no" == "override" ]]
then
	#Move timezones.txt
	cp "$timezone_file" "$user_path"
	result="$?"
else
	result=0
fi

#If file operation successful
if [[ $result = 0 ]]; then
	storePreference "TIMEZONE_PATH" "$user_path"
	
	#Notify
	echo -n "Using timezones.txt file from $user_path."
else
	#Notify
	echo -n "Sorry, unable to move to that location $user_path."
fi

exit