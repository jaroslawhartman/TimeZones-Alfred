source includes.sh

city="$1"
city_string="${city// /+}"

city="$(echo "$city" | sed 's/\\ / /g')"

[[ ! -z "$city" ]] && cat GeoLite2-City-Locations-en.csv | awk -F"," -v CITY="$city" '{if(tolower($11)~tolower(CITY)){print $0}};' | head -50 > /tmp/cities.tmp

if [[ ! -s /tmp/cities.tmp ]] 
then
	cat GeoLite2-City-Locations-en.csv | awk -F"," -v CITY="$city" '{if(tolower($13)~tolower(CITY)){print $0}};' | head -50 > /tmp/cities.tmp
fi

sort /tmp/cities.tmp | uniq > /tmp/cities2.tmp

echo '<?xml version="1.0"?>
	<items>'

if [[ ! -z "$city" ]]
then
	while IFS= read -r line
	do
		country=$(echo "$line" | awk -F',' '{print $6}' | sed -e 's|["'\'']||g')
		country_code=$(echo "$line" | awk -F',' '{print $5}' | sed -e 's|["'\'']||g')
		city_retrieved=$(echo "$line" | awk -F',' '{print $11}' | sed -e 's|["'\'']||g'  )
		region=$(echo "$line" | awk -F',' '{print $8}' | sed -e 's|["'\'']||g' )
		timezone=$(echo "$line" | awk -F',' '{print $13}' | sed -e 's|["'\'']||g' )

		echo '<item arg="'$country'|'$country_code'|'$city_retrieved'|'$timezone'" valid="yes">
		<title>'$city_retrieved", "$region'</title>	
		<subtitle>'$country' ('$country_code') , Timezone:' $timezone'</subtitle>
		</item>'
	done < '/tmp/cities2.tmp'
fi

[[ -e '/tmp/cities.tmp' ]] && rm '/tmp/cities.tmp'
[[ -e '/tmp/cities2.tmp' ]] && rm '/tmp/cities2.tmp'

echo '</items>'
