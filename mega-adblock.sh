#!/bin/bash
# Modified Pi-hole script to generate a generic hosts file
# for use with dnsmasq's addn-hosts configuration
# original : https://github.com/jacobsalmela/pi-hole/blob/master/gravity-adv.sh

set +o xtrace

# The Pi-hole now blocks over 120,000 ad domains
# Address to send ads to (the RPi)
piholeIP="8.8.8.8"
pinholeIPv6="2001:4860:4860::8888"
piholePTR="8.8.8.8 google-public-dns-a.google.com"

outhostlist='/tmp/blocklist.txt'
outdomainlist='/tmp/blockdns.txt'
adblockhosts='/tmp/adblock.hosts'
adblockdomains='/tmp/adblock.conf'
adblockblacklist='/tmp/adblock.blacklist'

echo "Getting yoyo ad list..." # Approximately 2452 domains at the time of writing
curl -s -d mimetype=plaintext -d hostformat=unixhosts http://pgl.yoyo.org/adservers/serverlist.php? | sort >> $outhostlist-$$

echo "Getting winhelp2002 ad list..." # 12985 domains
curl -s http://winhelp2002.mvps.org/hosts.txt | grep -v "#" | grep -v "127.0.0.1" | sed '/^$/d' | sed 's/\ /\\ /g' | awk '{print $2}' | sort >> $outhostlist-$$

echo "Getting adaway ad list..." # 445 domains
curl -s https://adaway.org/hosts.txt | grep -v "#" | grep -v "::1" | sed '/^$/d' | sed 's/\ /\\ /g' | awk '{print $2}' | grep -v '^\\' | grep -v '\\$' | sort >> $outhostlist-$$

echo "Getting hosts-file ad list..." # 28050 domains
curl -s http://hosts-file.net/.%5Cad_servers.txt | grep -v "#" | grep -v "::1" | sed '/^$/d' | sed 's/\ /\\ /g' | awk '{print $2}' | grep -v '^\\' | grep -v '\\$' | sort >> $outhostlist-$$

echo "Getting malwaredomainlist ad list..." # 1352 domains
curl -s http://www.malwaredomainlist.com/hostslist/hosts.txt | grep -v "#" | sed '/^$/d' | sed 's/\ /\\ /g' | awk '{print $3}' | grep -v '^\\' | grep -v '\\$' | sort >> $outhostlist-$$

echo "Getting adblock.gjtech ad list..." # 696 domains
curl -s http://adblock.gjtech.net/?format=unix-hosts | grep -v "#" | sed '/^$/d' | sed 's/\ /\\ /g' | awk '{print $2}' | grep -v '^\\' | grep -v '\\$' | sort >> $outhostlist-$$

echo "Getting someone who cares ad list..." # 10600
curl -s http://someonewhocares.org/hosts/hosts | grep -v "#" | sed '/^$/d' | sed 's/\ /\\ /g' | grep -v '^\\' | grep -v '\\$' | awk '{print $2}' | grep -v '^\\' | grep -v '\\$' | sort >> $outhostlist-$$

#echo "Getting Mother of All Ad Blocks list..." # 102168 domains!! Thanks Kacy
#curl -A 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' -e http://forum.xda-developers.com/ http://adblock.mahakala.is/ | grep -v "#" | awk '{print $2}' | sort >> $outhostlist-$$

# Sort the aggregated results and remove any duplicates
# Remove entries from the whitelist file if it exists at the root of the current user's home folder
echo "Removing duplicates and formatting the list of domains..."
cat $outhostlist-$$ | sed $'s/\r$//' | sort | uniq | sed '/^$/d' | awk -v "IP=$piholeIP" '{sub(/\r$/,""); print IP" "$0}'  > $outhostlist
cat $outhostlist-$$ | sed $'s/\r$//' | sort | uniq | sed '/^$/d' | awk '{sub(/\r$/,""); print $0}' > $adblockblacklist

# Count how many domains/whitelists were added splayed to the user
numberOfAdsBlocked=$(cat $outhostlist | wc -l | sed 's/^[ \t]*//')

echo "$numberOfAdsBlocked ad domains blocked."

which domain-sort.py
if [ $? -eq 0 ]; then
	echo "Generating dnsmasq local address..."
	grep "^[^\.]*\.[^\.]*$" $outhostlist-$$ > $outdomainlist-$$
	grep "^[^\.]*\.[^\.]*\.[^\.]*$" $outhostlist-$$ >> $outdomainlist-$$
	domain-sort.py $outdomainlist-$$ | sort | uniq | sed '/^$/d' | awk -v "IP=$piholeIP" '{sub(/\r$/,""); print "address=\"/"$0"/"IP"\""}' > $outdomainlist
	rm $outdomainlist-$$
fi

rm $outhostlist-$$

grep -v localhost.localdomain $outdomainlist > $adblockdomains
rm $outdomainlist
echo $piholePTR > $adblockhosts
grep -v -e localhost$ -e localdomain$ $outhostlist >> $adblockhosts
rm $outhostlist

#sed -i "s/$piholeIP/$pinholeIPv6/g" $adblockhosts
#sed -i "s/$piholeIP/$pinholeIPv6/g" $adblockdomains

