source includes.sh

growlnotify "Timezones updating. This will take a few moments..."

while IFS= read -r line
	do
	OIFS=$IFS
	IFS='|'
	data=($line)
	city="${data[0]}"
	city_returned="${data[1]}"
	country="${data[2]}"
	latitude="${data[3]}"
	longitude="${data[4]}"
	offset="${data[5]}"
	tz_id="${data[6]}"
	tz_name="${data[7]}"
	display_offset="${data[8]}"
	country_code="${data[9]}"
	IFS=$OIFS
	#growlnotify "Looking up $city"
	#Lookup city with Google timezone API
	api_timezone="$(curl --connect-timeout 10 -s "https://maps.googleapis.com/maps/api/timezone/xml?location=$latitude,$longitude&timestamp=$(date +%s)&sensor=false")"
	#echo "$api_timezone" >> ~/Desktop/timezone_result.xml #For debugging. Uncomment to save query result to Desktop
	#Parse returned info
	OIFS=$IFS
	IFS=$'\t'
	tz_data="$(php parsexml_timezone.php "$api_timezone")"
	tz_data_split=($tz_data)
	IFS=$OIFS
	
	if [[ -z "${country_code}" ]]
	then
	    new_country_code="$(curl --connect-timeout 20 -s "https://restcountries.eu/rest/v1/name/$country" | python -c 'import sys, json; print json.load(sys.stdin)[0]["callingCodes"][0]')"
	    echo $country_code >> /tmp/debug.log
	    let change++ 	#Increment count of changed cities
	fi

	if [ ! ${tz_data_split[0]} = OK ]; then
		if [ -z $problem ]; then
			echo "TimeZones update - $(date)"$'\n'$'\n'"The following places had problems and were not updated:" > "$HOME/Desktop/TimezonesUpdate_ERROR.txt"
		fi
		problem=1
		echo "$city, $country" >> "$HOME/Desktop/TimezonesUpdate_ERROR.txt"
		echo "$line" >> "$TZPREFS"/update_timezones.txt
		continue	
	else
		raw_offset="${tz_data_split[1]}"
		dst_offset="${tz_data_split[2]}"
		new_tz_id="${tz_data_split[3]}"
		new_tz_name="${tz_data_split[4]}"
		#growlnotify "$new_tz_name"

		#Convert offsets to integer values & Calculate single value offset
		raw_offset=$(echo "($raw_offset)/1" | bc)
		dst_offset=$(echo "($dst_offset)/1" | bc)
		new_offset=$(expr $raw_offset + $dst_offset)
		
		#Has it changed?
		if [ $new_offset = $offset ]; then
		    if [[ -z "$country_code" && -n "$new_country_code" ]]; then
		        # need to add CC
			    echo "$line|$new_country_code" >> "$TZPREFS"/update_timezones.txt
			else
		        # need to add CC
			    echo "$line" >> "$TZPREFS"/update_timezones.txt	
			fi		
			continue
		fi
		#Okay, so there's a change
		if [ -z $change ]; then
			echo "TimeZones update - $(date)"$'\n'$'\n'"The following places have changed their timezones since the last update:" > "$HOME/Desktop/TimezonesUpdate.txt"
		fi
		
		let change++ 	#Increment count of changed cities
				
		#Calculate UTC offset in hours (and prepare display values)
		UTC_offset=$(echo "scale=1;$new_offset/3600" | bc)
		UTC_offset=${UTC_offset/.0/} #Remove decimal if it's a whole number
		if [ $UTC_offset -lt 0 ]; then
			new_display_offset="UTC$UTC_offset"
		else
			new_display_offset="UTC+$UTC_offset"
		fi
		echo "$city|$city_returned|$country|$latitude|$longitude|$new_offset|$new_tz_id|$new_tz_name|$new_display_offset|$new_country_code" >> "$TZPREFS"/update_timezones.txt
		echo $'\n'"$city_returned, $country"$'\n'"- changed from $tz_name ($display_offset) to $new_tz_name ($new_display_offset)" >> "$HOME/Desktop/TimezonesUpdate.txt"
	fi
done < "$timezone_file"

mv -f "$TZPREFS"/update_timezones.txt "$timezone_file"

if [ $problem = 1 ]; then
	echo -n "Cities updated, but problems occured. See txt file on Desktop for details."
else
	if [ -z $change ]; then
		change=0
	fi
	if [ $change = 1 ]; then
		change_display="1 change"
	else
		change_display="$change changes"
	fi
	echo -n "City list updated successfully, with $change_display."
		if [ $change -gt 0 ]; then
			echo -n "See txt file on Desktop for details."
		fi
fi

