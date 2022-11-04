source includes.sh

city_definition="${1}"

	country=$(echo "$city_definition" | awk -F'|' '{ print $1 } ')
	country_code=$(echo "$city_definition" | awk -F'|' '{ print $2 } ')
	city=$(echo "$city_definition" | awk -F'|' '{ print $3 } ')
	timezone=$(echo "$city_definition" | awk -F'|' '{ print $4 } ')
        all_phone_codes="$(curl --connect-timeout 20 --silent http://country.io/phone.json)"
	phone_code="$(osascript -l JavaScript -e 'function run(argv) { return JSON.parse(argv[0])[argv[1]] }' "${all_phone_codes}" "${country_code}")"

	echo "$city|$country|$timezone|$country_code|$phone_code|1" >> "$timezone_file"
	sort -o "${timezone_file}.new" "$timezone_file" 

	mv "${timezone_file}.new" "$timezone_file"
	echo -n "$city, $country (+$phone_code) has been added to your list. Timezone: $timezone"
exit
