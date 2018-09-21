source includes.sh

FORMAT="$1"

echo "xxx $FORMAT" >> /tmp/xxx

storePreference "TIME_FORMAT" "$FORMAT"