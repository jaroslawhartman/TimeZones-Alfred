source includes.sh

#Split previous argument
OIFS=$IFS
IFS=','
arg=($1)
IFS=$OIFS
city="${arg[0]}"

cat "$timezone_file" | grep -v "$city" > /tmp/zonelist.tmp

mv /tmp/zonelist.tmp "$timezone_file"

echo -n "$city has been removed from your TimeZone list."