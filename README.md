# ad-mega-blocker

<pre>
In root's crontab

0  0 */3 * * mega-adblock.sh 2>&1 > /tmp/mega-adblock.log
2  0 */3 * * cp /tmp/adblock.blacklist /opt/dnscrypt-proxy-adfree/blacklist.txt
6  0 */3 * * systemctl restart dnscrypt-proxy-adfree
10 0 */3 * * rm -f /tmp/adblock.*bz2; bzip2 /tmp/adblock.*
</pre>
