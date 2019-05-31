source includes.sh

search="$1"	#Alfred argument

# Strip off time, e.g. in New York, 7:20
search="${search/,*/}"

tmp_timezone_file="${timezone_file}.tmp"

[[ -e "${tmp_timezone_file}" ]] && rm -rf "$tmp_timezone_file"

while IFS= read -r line
	do

	OIFS=$IFS
	IFS='|'		#Split stored line by delimiter
	data=($line)	#Create array
	city="${data[0]}"
	country="${data[1]}"
	timezone="${data[2]}"
    country_abbr="${data[3]}"
	country_code="${data[4]}"
	favourite="${data[5]}"

    if [[ -z "${favourite}" ]]; then
        favourite="1"
    fi

	if [[ "$city" == "$search"* ]]; then
        if [[ "${favourite}" == "0" ]]; then
            favourite="1"
        else
            favourite="0"
        fi
        selected_city="$city"
        selected_fav="$favourite"
    fi

    echo "$city|$country|$timezone|$country_abbr|$country_code|$favourite" >> "${tmp_timezone_file}"

done < "$timezone_file"

if [[ "$selected_fav" == "1" ]]
then
    echo "$selected_city has been un-pinned to the top of your list!"
else
    echo "$selected_city has been pinned from the top of your list!"
fi

cat "${tmp_timezone_file}" > "${timezone_file}"

[[ -e "${tmp_timezone_file}" ]] && rm -rf "$tmp_timezone_file"
