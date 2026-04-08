#!/bin/sh

# Vänta lite så nätverket hunnit komma upp
sleep 30

# Hämta skriptet, gör det körbart och kör update
uclient-fetch -q -O /tmp/blocklists.sh https://raw.githubusercontent.com/zoneme99/Home_Automation/main/blocklists.sh
chmod +x /tmp/blocklists.sh
/tmp/blocklists.sh update
