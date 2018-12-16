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

	if [[ "$line" == \#* ]]
	then
		continue
	fi

	# 	echo "$city|$country|$timezone|$country_code"

	OIFS=$IFS
	IFS='|'		#Split stored line by delimiter
	data=($line)	#Create array
	city="${data[0]}"
	country="${data[1]}"
	timezone="${data[2]}"
	country_abbr="${data[3]}"
	country_code="${data[4]}"
	favourite="${data[5]}"
	if [ -n "$country_code" ]
	then
	    country_code_string=" (+$country_code)"
	fi

	if [[ "$favourite" == "0" ]]
	then
	    favourite_string="⭐️ •"
	else
	    favourite_string=""	
	fi

	
	IFS=$OIFS


	# if [ $offset -ge 0 ]; then		#Add or subtract offset from UTC (in Unix epoch seconds)
	# 	city_epochtime=$(date -j -v "+$offset"S +%s ${timeToConvert})	
	# else
	# 	city_epochtime=$(date -j -v "$offset"S +%s ${timeToConvert}) 
	# fi
	# city_time=$(date -u -j -f %s $city_epochtime +"$TIME_FORMAT_STR") #Create readable time expression
	# city_date=$(date -u -j -f %s $city_epochtime +"%A %e %B %Y") #Create readable date expression

	local_tz=$(date +%z)

	if [[ ! -z "$timeToConvert" ]]
	then
		time_to_convert="-jf %H%M%z $timeToConvert$local_tz"
	else
		time_to_convert=''
	fi

	city_time=$(TZ=$timezone date $time_to_convert +"$TIME_FORMAT_STR")
	city_date=$(TZ=$timezone date $time_to_convert +"%A, %d %B" )

	#Determine flag icon
	country_flag=$(echo "$country" | tr '[A-Z]' '[a-z]')
	country_flag=${country_flag// /_}
	flag_icon=$country_flag.png
	if [ ! -e ./flags/$flag_icon ]; then
		flag_icon="_no_flag.png"
	fi
	#echo "$flag_icon" >> ~/Desktop/flags.txt
	if [[ "$city" == "$search"* ]]; then
		match=1
		echo '<item arg="'$city, $city_time'" valid="yes">
		<title>'$city: $city_time'</title>	
		<subtitle>'$favourite_string' on '$city_date' • '${country}${country_code_string}' • Timezone: '$timezone'</subtitle>
		<icon>./flags/'$flag_icon'</icon>
		</item>'
	fi
done < <(sort -k 6 -k 1 -t "|" "$timezone_file")

echo '</items>'

exit