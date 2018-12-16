source includes.sh

city_definition="${1}"

	country=$(echo "$city_definition" | awk -F'|' '{ print $1 } ')
	country_code=$(echo "$city_definition" | awk -F'|' '{ print $2 } ')
	city=$(echo "$city_definition" | awk -F'|' '{ print $3 } ')
	timezone=$(echo "$city_definition" | awk -F'|' '{ print $4 } ')
	phone_code="$(curl --connect-timeout 20 -s https://restcountries.eu/rest/v2/alpha/$country_code | python -c 'import sys, json; print json.load(sys.stdin)["callingCodes"][0]')"

	echo "$city|$country|$timezone|$country_code|$phone_code|1" >> "$timezone_file"
	sort -o "${timezone_file}.new" "$timezone_file" 

	mv "${timezone_file}.new" "$timezone_file"
	echo -n "$city, $country (+$phone_code) has been added to your list. Timezone: $timezone"
exit
