
devicelog()
{
   local VARIABLE=${1}

   if [ -f "$BB_HASHLOCATION" ]; then
      local AUTHORIZATION=$(<$BB_HASHLOCATION)
   else
      local AUTHORIZATION="UNKNOWN"
   fi
   curl --connect-timeout 5 \
      --max-time 20 \
      -s -X POST https://blackbox.surfwijzer.nl/api/devicelog \
      -H "User-Agent: surfwijzerblackbox" \
      -H "Cache-Control: private, max-age=0, no-cache" \
      -H "Authorization: $AUTHORIZATION" \
      -H "X-Script: $SCRIPT_FILENAME" \
      -e $SCRIPT_FILENAME \
      -d text="$VARIABLE" \
      -d sf="$SCRIPT_FILENAME">/dev/null
}
