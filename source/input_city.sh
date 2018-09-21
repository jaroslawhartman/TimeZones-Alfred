source includes.sh

city="$1"
city_string="${city// /+}"

api_places="$(curl --connect-timeout 7 -s "https://maps.googleapis.com/maps/api/place/autocomplete/xml?input=$city&sensor=false&key=AIzaSyA6SK-VsY6dfOb6p6dmshEvgccDuFLVsew")"

#echo "$api_places" > ~/Desktop/place_result_$city_string.xml #For debugging. Uncomment to save query result to Desktop

place_data="$(php parsexml_places.php "$api_places")"

#echo "$place_data" > ~/Desktop/output_$city_string.xml
IFS=$'\n'
places=($place_data)


if [ ! "${places[0]}" = OK ]; then
	echo '<?xml version="1.0"?>
		<items>
		<item uid="NA" valid="no">
			<title>Sorry...</title>	
			<subtitle>There was a problem finding your place.</subtitle>
			<icon>./flags/_no_flag.png</icon>
		</item>
		</items>'
	exit
fi

#Show results
echo '<?xml version="1.0"?>
	<items>'
OLD_IFS=$IFS

for i in "${places[@]}"
do
	if [ $i = OK ];then
		continue
	fi
	place="$i"
	IFS=$','
	strip=($i)
	IFS=$OLD_IFS
	country=${strip[$((${#strip[@]}-1))]}
	country=${country/ /} #strip spaces
	locale="${strip[0]}"
	#Determine flag icon
	country_flag=$(echo "$country" | tr '[A-Z]' '[a-z]')
	country_flag=${country_flag// /_}
	flag_icon=$country_flag.png
	if [ ! -e ./flags/$flag_icon ]; then
		#growlnotify "Missing flag - $country! Please report this to the workflow's creator."
		flag_icon="_no_flag.png"
	fi

	echo '<item uid="'$i'" arg="'$place'" valid="yes">
		<title>'$place'</title>	
		<subtitle>Add '$locale' to your Timezone list.</subtitle>
		<icon>./flags/'$flag_icon'</icon>
		</item>'
done
echo '</items>'


exit
