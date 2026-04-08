#!/bin/sh
DL="uclient-fetch -q -O"

HOSTS="/tmp/hosts.d"
TMP="/tmp/bl-tmp"
SOCIAL_BAK="/tmp/hosts.d/.social-bak"
STREAM_BAK="/tmp/hosts.d/.stream-bak"

mkdir -p "$HOSTS" "$TMP"

WHITELIST="whatsapp.com
whatsapp.net
web.whatsapp.com
mmg.whatsapp.net
media.whatsapp.com
static.whatsapp.net
messenger.com
www.messenger.com
m.me
edge-chat.messenger.com
star.c10r.facebook.com
b-api.facebook.com
b-graph.facebook.com
mqtt-mini.facebook.com
upload.facebook.com
signal.org
updates.signal.org
textsecure-service.whispersystems.org
cdn.signal.org
cdn2.signal.org
storage.signal.org
telegram.org
t.me
telegram.me
api.telegram.org
web.telegram.org
desktop.telegram.org
viber.com
chatapi.viber.com
discord.com
discordapp.com
cdn.discordapp.com
gateway.discord.gg
media.discordapp.net
zoom.us
teams.microsoft.com
skype.com
reddit.com
www.reddit.com
old.reddit.com
new.reddit.com
redd.it
i.redd.it
v.redd.it
preview.redd.it
external-preview.redd.it
redditmedia.com
reddituploads.com
redditstatic.com
redditsave.com"

filter_whitelist() {
    local infile="$1"
    echo "$WHITELIST" | while IFS= read -r d; do
        [ -z "$d" ] && continue
        sed -i "/[[:space:]]${d}$/d" "$infile"
        sed -i "/[[:space:]]www\.${d}$/d" "$infile"
    done
}

add_ipv6() {
    local f="$1"
    [ -s "$f" ] && sed -n 's/^0\.0\.0\.0 /:: /p' "$f" >> "$f"
}

reload_dns() {
    /etc/init.d/dnsmasq restart 2>/dev/null
}

case "$1" in

update)
    logger -t blocklist "Startar uppdatering..."

    $DL "$TMP/sb.txt" \
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts"
    if [ -s "$TMP/sb.txt" ]; then
        grep "^0\.0\.0\.0 " "$TMP/sb.txt" | \
            grep -v "0\.0\.0\.0 0\.0\.0\.0" > "$HOSTS/stevenblack"
        logger -t blocklist "StevenBlack: $(wc -l < "$HOSTS/stevenblack") domäner"
    else
        logger -t blocklist "FEL: StevenBlack nedladdning misslyckades"
    fi

    $DL "$TMP/soc.txt" \
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts"
    if [ -s "$TMP/soc.txt" ]; then
        grep "^0\.0\.0\.0 " "$TMP/soc.txt" | \
            grep -v "0\.0\.0\.0 0\.0\.0\.0" > "$TMP/soc-clean.txt"
        filter_whitelist "$TMP/soc-clean.txt"
        add_ipv6 "$TMP/soc-clean.txt"
        cp "$TMP/soc-clean.txt" "$SOCIAL_BAK"
        cp "$TMP/soc-clean.txt" "$HOSTS/social-sched"
        logger -t blocklist "Social: $(wc -l < "$HOSTS/social-sched") rader"
    else
        logger -t blocklist "FEL: Social nedladdning misslyckades"
    fi

    cat > "$TMP/stream.txt" << 'STREAM'
0.0.0.0 netflix.com
0.0.0.0 www.netflix.com
0.0.0.0 api-global.netflix.com
0.0.0.0 appboot.netflix.com
0.0.0.0 nflxvideo.net
0.0.0.0 nflximg.net
0.0.0.0 nflxext.com
0.0.0.0 nflxso.net
0.0.0.0 youtube.com
0.0.0.0 www.youtube.com
0.0.0.0 m.youtube.com
0.0.0.0 youtubei.googleapis.com
0.0.0.0 youtube-ui.l.google.com
0.0.0.0 yt3.ggpht.com
0.0.0.0 ytimg.com
0.0.0.0 i.ytimg.com
0.0.0.0 s.ytimg.com
0.0.0.0 googlevideo.com
0.0.0.0 youtu.be
0.0.0.0 youtube-nocookie.com
0.0.0.0 disneyplus.com
0.0.0.0 www.disneyplus.com
0.0.0.0 disney-plus.net
0.0.0.0 bamgrid.com
0.0.0.0 disneystreaming.com
0.0.0.0 dssott.com
0.0.0.0 max.com
0.0.0.0 www.max.com
0.0.0.0 hbomax.com
0.0.0.0 play.max.com
0.0.0.0 primevideo.com
0.0.0.0 www.primevideo.com
0.0.0.0 atv-ps.amazon.com
0.0.0.0 svtplay.se
0.0.0.0 www.svtplay.se
0.0.0.0 tv4play.se
0.0.0.0 www.tv4play.se
0.0.0.0 twitch.tv
0.0.0.0 www.twitch.tv
0.0.0.0 m.twitch.tv
0.0.0.0 player.twitch.tv
0.0.0.0 tiktok.com
0.0.0.0 www.tiktok.com
0.0.0.0 m.tiktok.com
0.0.0.0 musical.ly
STREAM
    add_ipv6 "$TMP/stream.txt"
    cp "$TMP/stream.txt" "$STREAM_BAK"
    cp "$TMP/stream.txt" "$HOSTS/stream-sched"
    logger -t blocklist "Streaming: $(wc -l < "$HOSTS/stream-sched") rader"

    reload_dns
    rm -rf "$TMP"
    logger -t blocklist "Uppdatering klar."
    ;;

on)
    [ -f "$SOCIAL_BAK" ] && cp "$SOCIAL_BAK" "$HOSTS/social-sched"
    [ -f "$STREAM_BAK" ] && cp "$STREAM_BAK" "$HOSTS/stream-sched"
    reload_dns
    logger -t blocklist "Schema ON — social+streaming BLOCKERAT"
    ;;

off)
    > "$HOSTS/social-sched"
    > "$HOSTS/stream-sched"
    reload_dns
    logger -t blocklist "Schema OFF — social+streaming TILLÅTET"
    ;;

*)
    echo "Användning: $0 {update|on|off}"
    ;;
esac
