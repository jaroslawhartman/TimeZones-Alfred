source includes.sh

search="$1"	#Alfred argument

# Check if argument could be a time in one of the formats:
# HH
# HH:MM
# HHMM

re='^[0-9]+'
if [[ $search =~ $re ]] ; then

    # HH
    if [[ $search =~ ^[0-9]{2}$ ]]; then
        echo "2 digits" >> /tmp/alfred.txt
        search=$search"00"
    fi
    
    # H (pad to 0H)
    if [[ $search =~ ^[0-9]{1}$ ]]; then
        echo "1 digit" >> /tmp/alfred.txt
        search="0"$search"00"
    fi
    
    # H: (pad to 0H:)
    if [[ $search =~ ^[0-9]{1}\: ]]; then
        echo "1 digit" >> /tmp/alfred.txt
        search="0"$search
    fi    
    
    search="${search//:}"

    echo ${search} >> /tmp/alfred.txt
    timeToConvert=${search}
    search=""
fi

#Populate Alfred results with Timezones list
echo '<?xml version="1.0"?>
	<items>'

match=0		#use to determine if there are any matches to the current query in Alfred


if [[ "$TIME_FORMAT" = "24h" ]]; then
    TIME_FORMAT_STR='%k:%M'

else
    TIME_FORMAT_STR='%l:%M %p'
fi

while IFS= read -r line
	do
	OIFS=$IFS
	IFS='|'		#Split stored line by delimiter
	data=($line)	#Create array
	city="${data[0]}"
	city_returned="${data[1]}"
	country="${data[2]}"
	offset="${data[5]}"
	tz_id="${data[6]}"
	tz_name="${data[7]}"
	display_offset="${data[8]}"
	country_code="${data[9]}"
	country_code_string=""
	if [ -n "$country_code" ]
	then
	    country_code_string="(+$country_code)"
	fi
	IFS=$OIFS
	if [ $offset -ge 0 ]; then		#Add or subtract offset from UTC (in Unix epoch seconds)
		city_epochtime=$(date -j -v "+$offset"S +%s ${timeToConvert})	
	else
		city_epochtime=$(date -j -v "$offset"S +%s ${timeToConvert}) 
	fi
	city_time=$(date -u -j -f %s $city_epochtime +"$TIME_FORMAT_STR") #Create readable time expression
	city_date=$(date -u -j -f %s $city_epochtime +"%A %e %B %Y") #Create readable date expression
	#Determine flag icon
	country_flag=$(echo "$country" | tr '[A-Z]' '[a-z]')
	country_flag=${country_flag// /_}
	flag_icon=$country_flag.png
	if [ ! -e ./flags/$flag_icon ]; then
		#growlnotify "Missing flag - $country! Please report this to the workflow's creator."
		flag_icon="_no_flag.png"
	fi
	#echo "$flag_icon" >> ~/Desktop/flags.txt
	if [[ "$city" == "$search"* ]]; then
		match=1
		echo '<item arg="'$city_returned'|'$city_time'|'$city_date'|'$country'|'$tz_name'|'$display_offset'" valid="yes">
		<title>'$city_returned: $city_time'</title>	
		<subtitle>on '$city_date'  •  '$country' '$country_code_string'• '$tz_name' ('$display_offset')</subtitle>
		<icon>./flags/'$flag_icon'</icon>
		</item>'
	fi
	done < "$timezone_file"

##Custom Lookup starts here
if [ $match = 0 ]; then
	
	city="$search"
	if [ ${#city} -lt 3 ]; then
		echo '<item uid="NA" valid="no">
		<title>Time In?</title>	
		<subtitle>Enter a place name.</subtitle>
		<icon>icon.png</icon>
		</item>
		</items>'
		exit
	fi
	
	city_string="${city// /+}"

	api_location="$(curl --connect-timeout 20 -s "http://maps.googleapis.com/maps/api/geocode/xml?address=$city_string&sensor=false")"

	#echo "$api_location" > "$HOME/Desktop/result_$city_string.xml" #For debugging. Uncomment to save query result to Desktop

	data="$(php parsexml_location.php "$api_location")"

	#Split output data query into array
	IFS=$'\t'
	data_split=($data)

	if [ ! ${data_split[0]} = OK ]; then
		echo '<item uid="NA" valid="no">
		<title>Sorry...</title>	
		<subtitle>No matches for '$search'</subtitle>
		<icon>./flags/_no_flag.png</icon>
		</item>
		</items>'
		exit
	fi

	city_returned="${data_split[1]}"
	latitude="${data_split[2]}"
	longitude="${data_split[3]}"
	country="${data_split[4]}"
	country_code="$(curl --connect-timeout 20 -s "https://restcountries.eu/rest/v1/name/$country" | python -c 'import sys, json; print json.load(sys.stdin)[0]["callingCodes"][0]')"
	if [ -n "$country_code" ]
	then
	    country_code_string="(+$country_code)"
	fi

	#growlnotify "City: $city_returned"$'\n'"Lat: $latitude"$'\n'"Lng: $longitude"$'\n'"Country: $country"

	#Now use Lng/Lat data to look up Timezone

	api_timezone="$(curl --connect-timeout 20 -s "https://maps.googleapis.com/maps/api/timezone/xml?location=$latitude,$longitude&timestamp=$(date +%s)&sensor=false")"

	#echo "$api_timezone" > "$HOME/Desktop/result_tz_$city_string.xml" #For debugging. Uncomment to save query result to Desktop

	tz_data="$(php parsexml_timezone.php "$api_timezone")"

	tz_data_split=($tz_data)

	if [ ! ${data_split[0]} = OK ]; then
		echo '<item uid="NA" valid="no">
		<title>Sorry...</title>	
		<subtitle>No matches for '$search'</subtitle>
		<icon>./flags/_no_flag.png</icon>
		</item>
		</items>'
		exit
	fi

	raw_offset="${tz_data_split[1]}"
	dst_offset="${tz_data_split[2]}"
	tz_id="${tz_data_split[3]}"
	tz_name="${tz_data_split[4]}"

	#Convert offsets to integer values & Calculate single value offset
	raw_offset=$(echo "($raw_offset)/1" | bc)
	dst_offset=$(echo "($dst_offset)/1" | bc)
	offset=$(expr $raw_offset + $dst_offset)

	#Calculate UTC offset in hours (and prepare display values)
	UTC_offset=$(echo "scale=1;$offset/3600" | bc)
	UTC_offset=${UTC_offset/.0/} #Remove decimal if it's a whole number
	if [ $UTC_offset -lt 0 ]; then
		display_offset="UTC$UTC_offset"
	else
		display_offset="UTC+$UTC_offset"
	fi

	#Calculate the current time in the required location
	if [ $offset -ge 0 ]; then		#Add or subtract offset from UTC (in Unix epoch seconds)
			city_epochtime=$(date -v "+$offset"S +%s)	
	else
		city_epochtime=$(date -v "$offset"S +%s) 
	fi
	

	
	city_time=$(date -u -j -f %s $city_epochtime +"$TIME_FORMAT_STR") #Create readable time expression
	city_date=$(date -u -j -f %s $city_epochtime +"%A %e %B %Y") #Create readable date expression
	#Determine flag icon
	country_flag=$(echo "$country" | tr '[A-Z]' '[a-z]')
	country_flag=${country_flag// /_}
	flag_icon=$country_flag.png
	if [ ! -e ./flags/$flag_icon ]; then
		growlnotify "Missing flag - $country! Please report this to the workflow's creator."
		flag_icon="_no_flag.png"
	fi
	echo '<item uid="custom" arg="'$city_returned'|'$city_time'|'$city_date'|'$country'|'$tz_name'|'$display_offset'" valid="yes">
		<title>'$city_returned: $city_time'</title>	
		<subtitle>on '$city_date'  •  '$country' '$country_code_string'• '$tz_name' ('$display_offset')</subtitle>
		<icon>./flags/'$flag_icon'</icon>
		</item>'
fi
echo '</items>'

IFS=$OLD_IFS
exit