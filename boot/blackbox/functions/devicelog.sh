


devicelog()
{
   local VARIABLE=${1}
   local FILE=/var/www/blackbox.id
   if [ -f "$FILE" ]; then
      local AUTHORIZATION=$(</var/www/blackbox.id)
   else
      local AUTHORIZATION="UNKNOWN"
   fi
   curl --connect-timeout 5 \
      --max-time 20 \
      --retry 5 \
      --retry-delay 0 \
      --retry-max-time 40 \
      -s -X POST https://blackbox.surfwijzer.nl/api/devicelog \
      -H "User-Agent: surfwijzerblackbox" \
      -H "Cache-Control: private, max-age=0, no-cache" \
      -H "Authorization: $AUTHORIZATION" \
      -H "X-Script: $SCRIPT_FILENAME" \
      -e "$SCRIPT_FILENAME" \
      -d text="$VARIABLE" >/dev/null
}
