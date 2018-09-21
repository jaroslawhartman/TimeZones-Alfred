source includes.sh

city="$1"
city_string="${city// /+}"

api_location="$(curl --connect-timeout 20 -s "http://maps.googleapis.com/maps/api/geocode/xml?address=$city_string&sensor=false")"

#echo "$api_location" > ~/Desktop/location_result.xml #For debugging. Uncomment to save query result to Desktop

data="$(php parsexml_location.php "$api_location")"

#Split output data query into array
IFS=$'\t'
data_split=($data)

if [ ! ${data_split[0]} = OK ]; then
	echo "Sorry. There was a problem trying to add \"$city\" to your TimeZone list."
	exit
fi

city_returned="${data_split[1]}"
latitude="${data_split[2]}"
longitude="${data_split[3]}"
country="${data_split[4]}"

country_code="$(curl --connect-timeout 20 -s "https://restcountries.eu/rest/v1/name/$country" | python -c 'import sys, json; print json.load(sys.stdin)[0]["callingCodes"][0]')"

#echo "$country, $country_code" >> /tmp/debug.log

#growlnotify "City: $city_returned"$'\n'"Lat: $latitude"$'\n'"Lng: $longitude"$'\n'"Country: $country"

#Now use Lng/Lat data to look up Timezone

api_timezone="$(curl --connect-timeout 20 -s "https://maps.googleapis.com/maps/api/timezone/xml?location=$latitude,$longitude&timestamp=$(date +%s)&sensor=false")"

#echo "$api_timezone" > ~/Desktop/timezone_result.xml #For debugging. Uncomment to save query result to Desktop

tz_data="$(php parsexml_timezone.php "$api_timezone")"

tz_data_split=($tz_data)

if [ ! ${data_split[0]} = OK ]; then
	echo "Sorry. There was a problem trying to add \"$city\" to your TimeZone list."
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

#growlnotify "Raw: $raw_offset"$'\n'"dst: $dst_offset"$'\n'"Offset: $offset"$'\n'"UTC: $UTC_offset"$'\n'"ID: $tz_id"$'\n'"Name: $tz_name"
#echo "Raw: $raw_offset"$'\n'"dst: $dst_offset"$'\n'"Offset: $offset"$'\n'"UTC: $UTC_offset"$'\n'"ID: $tz_id"$'\n'"Name: $tz_name" > ~/Desktop/values.txt

#Save data to txt file

echo "$city|$city_returned|$country|$latitude|$longitude|$offset|$tz_id|$tz_name|$display_offset|$country_code" >> "$timezone_file"

#Show notification
echo -n "$city_returned, $country (+$country_code) has been added to your list. Timezone: $display_offset"