
devicelog()
{
   local VARIABLE=${1}

   if [ -f "$BB_HASHLOCATION" ]; then
      local AUTHORIZATION=$(<$BB_HASHLOCATION)
   else
     if [ -f "$TMP_POSTDATAHASH" ]; then
       local AUTHORIZATION=$(<$TMP_POSTDATAHASH)
     else
       local AUTHORIZATION="UNKNOWN"
     fi
   fi
   curl --connect-timeout 5 \
      --max-time 20 \
      -s -X POST https://api.surfwijzer.nl/blackbox/api/devicelog \
      -H "User-Agent: surfwijzerblackbox" \
      -H "Cache-Control: private, max-age=0, no-cache" \
      -H "Authorization: $AUTHORIZATION" \
      -H "X-Script: $SCRIPT_FILENAME" \
      -e $SCRIPT_FILENAME \
      -d text="$VARIABLE" \
      -d sf="$SCRIPT_FILENAME">/dev/null
}
