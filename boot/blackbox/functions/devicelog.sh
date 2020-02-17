


devicelog()
{
   local VARIABLE=${1}
   curl --connect-timeout 5 \
      --max-time 20 \
      --retry 5 \
      --retry-delay 0 \
      --retry-max-time 40 \
      -s -X POST https://blackbox.surfwijzer.nl/api/devicelog \
      -H "User-Agent: surfwijzerblackbox" \
      -H "Cache-Control: private, max-age=0, no-cache" \
      -H "X-Script: log.sh" \
      -e "log.sh" \
      -d text="$VARIABLE" >/dev/null
}
