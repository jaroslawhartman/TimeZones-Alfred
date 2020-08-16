source includes.sh

search="$1"	#Alfred argument

# Argument can be empty or have 1, 2 or 3 space separated components
# empty: use current time on current date at local timezone
# one component: <time> or <city> - use given time on current date at local timezone or sarch for city
# two components: <date modification> <time> - use given time on calculated date at local timezone
# three components: <source timezone> <date modification> <time> - use given time on calculated date at given source timezone

# <time> can have following formats:
# HH (assume minutes to be zero)
# HH:MM
# HHMM

# <date modification> can have following formats:
# t (short for today)
# today
# tm (short for tomorrow)
# tomorrow
# DD (assume current month and year)
# MMDD (assume current year)
# YYMMDD
# DDd (DD days added to today)

# <source timezone> can have following formats:
# CITY (to be looked up in /usr/share/zoneinfo.default)

comp1=$(echo "$search" | awk -F'[[:space:]]+' '{print $1}')
comp2=$(echo "$search" | awk -F'[[:space:]]+' '{print $2}')
comp3=$(echo "$search" | awk -F'[[:space:]]+' '{print $3}')

if [ -n "$comp3" ]
then
    source_timezone_search=$comp1
    date_modification_search=$comp2
    time_search=$comp3
elif [ -n "$comp2" ]
then
    date_modification_search=$comp1
    time_search=$comp2
else
    if [[ "$comp1" =~ ^[0-9]+ ]]
    then
        time_search=$comp1
    else
        city_search=$comp1
    fi
fi

#
# create source timezone
#
if [ -n "$source_timezone_search" ]
then
    #timezoneToConvert=$(find /usr/share/zoneinfo.default -iname "*${source_timezone_search}*" | head -1 )
    #timezoneToConvert=${timezoneToConvert:28}
    timezoneToConvert=$(cat "$timezone_file" | awk -v query="$source_timezone_search" -F'|' 'tolower($1) ~ tolower(query) {print $3}' )
    if [ -n "$timezoneToConvert" ]
    then
        timezoneOffsetToConvert=$(TZ=$timezoneToConvert date +%z)
    fi
fi
if [ -z "$timezoneOffsetToConvert" ]
then
    timezoneOffsetToConvert=$(date +%z)
fi

#
# create source date
#
if [ 'tm' = "$date_modification_search" -o 'tomorrow' = "$date_modification_search" ]
then
    dateToConvert=$(date -v +1d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]+d$ ]]
then
    dateToConvert=$(date -v +${date_modification_search} +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{1,2}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{3}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:1}m -v ${date_modification_search:1}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{4}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:2}m -v ${date_modification_search:2}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{5}$ ]]
then
    dateToConvert=$(date -v 20${date_modification_search:0:1}y -v ${date_modification_search:1:2}m -v ${date_modification_search:3}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{6}$ ]]
then
    dateToConvert=$(date -v 20${date_modification_search:0:2}y -v ${date_modification_search:2:2}m -v ${date_modification_search:4}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{8}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:4}y -v ${date_modification_search:4:2}m -v ${date_modification_search:6}d +%Y%m%d)
else
    # fallback that also covers 't' and 'today'
    dateToConvert=$(date +%Y%m%d)
fi

#
# create source time
#
if [[ $time_search =~ ^[0-9:]+$ ]] ; then

    # HH
    if [[ $time_search =~ ^[0-9]{2}$ ]]; then
        #echo "2 digits" >> /tmp/alfred.txt
        time_search=${time_search}00
    fi
    
    # H (pad to 0H)
    if [[ $time_search =~ ^[0-9]{1}$ ]]; then
        #echo "1 digit" >> /tmp/alfred.txt
        time_search=0${time_search}00
    fi
    
    # H: (pad to 0H:)
    if [[ $time_search =~ ^[0-9]{1}\: ]]; then
        #echo "1 digit" >> /tmp/alfred.txt
        time_search=0${time_search}
    fi    
    
    # pad seconds
    time_search=${time_search//:}00

    #echo ${time_search} >> /tmp/alfred.txt
    timeToConvert=${time_search}

    # todo this is weird
    time_search=
else
    timeToConvert=$(date +%H%M)00
    time_search=
fi

#Populate Alfred results with Timezones list
echo '<?xml version="1.0"?>
    <items>'

match=0		#use to determine if there are any matches to the current query in Alfred


if [[ "$TIME_FORMAT" = "24h" ]]; then
    TIME_FORMAT_STR='%0k:%M'
fi

if [[ "$TIME_FORMAT" = "12h" ]]; then
    TIME_FORMAT_STR='%-l:%M %p'
fi

if [[ "$TIME_FORMAT" = "Both" ]]; then
    # Both - 24hr (12hr)
    TIME_FORMAT_STR='%0k:%M (%-l:%M %p)'
fi 

sortkey=1

while IFS='|' read -r city country timezone country_code telephone_code favourite
    do

    # skip comment line
    if [[ "$city" =~ ^[[:space:]]*\# ]]
    then
        continue
    fi

    if [[ -n "$telephone_code" ]]
    then
        telephone_code_string=" (+$telephone_code)"
    else
        telephone_code_string=""
    fi

    if [[ "$favourite" == "0" ]]
    then
        favourite_string="⭐️ •"
    else
        favourite_string=""	
    fi
    
    if [ "$timezone" = "$timezoneToConvert" ]
    then
        sourceTimezone_string="👉 "
    else
        sourceTimezone_string=""
    fi
    
    setTimeOptionArguments="-jf %Y%m%d%H%M%S%z $dateToConvert$timeToConvert$timezoneOffsetToConvert"

    city_time=$(TZ=$timezone date $setTimeOptionArguments +"$TIME_FORMAT_STR")
    city_date=$(TZ=$timezone date $setTimeOptionArguments +"%A, %d %B %Y" )

    #Determine flag icon
    country_flag="$(echo "$country" | tr '[A-Z]' '[a-z]')"
    country_flag="${country_flag// /_}"
    flag_icon="$country_flag.png"
    if [[ ! -e "./flags/$flag_icon" ]]; then
        flag_icon="_no_flag.png"
    fi

    # It shall be possible to disable sorting
    # in fact, it means we're assiging an incremaental sort key
    if [[ ! "$SORTING" == "n" ]]
    then
        # we start the output with a sort key to simply pipe the result to 'sort'
        # we sort first by favourite, second by time ascending, third by city name
        sortkey=$favourite$(TZ=$timezone date $setTimeOptionArguments +%Y%m%d%H%M )"$city"
    else   
        sortkey=$(printf "%03d" $(( 10#$sortkey + 1 )))
    fi

    if [[ "$city" =~ ${city_search:-.} ]]; then
        match=1
        echo "<!--$sortkey-->\
              <item arg=\"$city, $city_time\" valid=\"yes\">\
                  <title>$sourceTimezone_string$city: $city_time</title>\
                  <subtitle>$favourite_string on $city_date • ${country}${telephone_code_string} • Timezone: $timezone</subtitle>\
                  <icon>./flags/$flag_icon</icon>\
              </item>"
    fi
done < "$timezone_file" | sort

echo '</items>'

exit