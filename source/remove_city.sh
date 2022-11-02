source includes.sh

set -x

#Split previous argument
OIFS=$IFS
IFS=','
arg=($1)
IFS=$OIFS
city="${arg[0]}"

# searchip off time, e.g. in New York, 7:20
# searching passed: 7:20 (New York)
# extract City from the braces
city=${city#*(}
city=${city%)*}

cat "$timezone_file" | grep -v "$city" > /tmp/zonelist.tmp

mv /tmp/zonelist.tmp "$timezone_file"

echo -n "$city has been removed from your TimeZone list."
