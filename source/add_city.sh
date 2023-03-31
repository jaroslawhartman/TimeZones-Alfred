source includes.sh

city_definition="${1}"

	country=$(echo "$city_definition" | awk -F'|' '{ print $1 } ')
	country_code=$(echo "$city_definition" | awk -F'|' '{ print $2 } ')
	city=$(echo "$city_definition" | awk -F'|' '{ print $3 } ')
	timezone=$(echo "$city_definition" | awk -F'|' '{ print $4 } ')

	echo "$city|$country|$timezone|$country_code|1" >> "$timezone_file"
	sort -o "${timezone_file}.new" "$timezone_file"

	mv "${timezone_file}.new" "$timezone_file"
	echo -n "$city, $country has been added to your list. Timezone: $timezone"
exit
