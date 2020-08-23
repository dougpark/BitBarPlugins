#!/bin/bash
# Doug 8/23/2020
# <bitbar.title>net-status</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.desc>
# Combined: got-internet.sh, ping.sh and net-info.sh
# If got-internet returns true then do ping and net-info
# </bitbar.desc>
# <bitbar.dependencies>got-internet.sh</bitbar.dependencies>
# <bitbar.dependencies>ping.sh</bitbar.dependencies>
# <bitbar.dependencies>net-info.sh</bitbar.dependencies>

function display-ping {
		
	# ##################################################################################################
	# <bitbar.title>ping</bitbar.title>
	# <bitbar.version>v1.1</bitbar.version>
	# <bitbar.author>Trung Đinh Quang, Grant Sherrick and Kent Karlsson</bitbar.author>
	# <bitbar.author.github>thealmightygrant</bitbar.author.github>
	# <bitbar.desc>Sends pings to a range of sites to determine network latency</bitbar.desc>
	# <bitbar.image>http://i.imgur.com/lk3iGat.png?1</bitbar.image>
	# <bitbar.dependencies>ping</bitbar.dependencies>

	# This is a plugin of Bitbar
	# https://github.com/matryer/bitbar
	# It shows current ping to some servers at the top Menubar
	# This helps me to know my current connection speed
	#
	# Authors: (Trung Đinh Quang) trungdq88@gmail.com and (Grant Sherrick) https://github.com/thealmightygrant

	# Themes copied from here: http://colorbrewer2.org/
	# shellcheck disable=SC2034
	PURPLE_GREEN_THEME=("#762a83" "#9970ab" "#c2a5cf" "#a6dba0" "#5aae61" "#1b7837")
	# shellcheck disable=SC2034
	RED_GREEN_THEME=("#d73027" "#fc8d59" "#fee08b" "#d9ef8b" "#91cf60" "#1a9850")
	# shellcheck disable=SC2034
	ORIGINAL_THEME=("#acacac" "#ff0101" "#cc673b" "#ce8458" "#6bbb15" "#0ed812")

	# Configuration
	COLORS=(${RED_GREEN_THEME[@]})
	MENUFONT="" #size=10 font=UbuntuMono-Bold"
	FONT=""
	MAX_PING=1000
	SITES=(8.8.8.8 192.168.1.1 192.168.2.254)

	#grab ping times for all sites
	SITE_INDEX=0
	PING_TIMES=

	while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
		NEXT_SITE="${SITES[$SITE_INDEX]}"
		if RES=$(ping -c 2 -n -q "$NEXT_SITE" 2>/dev/null); then
			NEXT_PING_TIME=$(echo "$RES" | awk -F '/' 'END {printf "%.0f\n", $5}')
		else
			NEXT_PING_TIME=$MAX_PING
		fi

		if [ -z "$PING_TIMES" ]; then
			PING_TIMES=($NEXT_PING_TIME)
		else
			PING_TIMES=(${PING_TIMES[@]} $NEXT_PING_TIME)
		fi
		SITE_INDEX=$(( SITE_INDEX + 1 ))
	done

	# Calculate the average ping
	SITE_INDEX=0
	AVG=0
	while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
		AVG=$(( (AVG + ${PING_TIMES[$SITE_INDEX]}) ))
		SITE_INDEX=$(( SITE_INDEX + 1 ))
	done
	AVG=$(( AVG / ${#SITES[@]} ))

	# Calculate STD dev
	SITE_INDEX=0
	AVG_DEVS=0
	while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
		AVG_DEVS=$(( AVG_DEVS + (${PING_TIMES[$SITE_INDEX]} - AVG)**2 ))
		SITE_INDEX=$(( SITE_INDEX + 1 ))
	done
	AVG_DEVS=$(( AVG_DEVS / ${#SITES[@]} ))
	SD=$(echo "sqrt ( $AVG_DEVS )" | bc -l | awk '{printf "%d\n", $1}')

	if [ $AVG -ge $MAX_PING ]; then
	MSG=" ❌ "
	else
	MSG='⚡'"$AVG"'±'"$SD"
	fi

	function colorize {
	if [ "$1" -ge $MAX_PING ]; then
		echo "${COLORS[0]}"
	elif [ "$1" -ge 600 ]; then
		echo "${COLORS[1]}"
	elif [ "$1" -ge 300 ]; then
		echo "${COLORS[2]}"
	elif [ "$1" -ge 100 ]; then
		echo "${COLORS[3]}"
	elif [ "$1" -ge 50 ]; then
		echo "${COLORS[4]}"
	else
		echo "${COLORS[5]}"
	fi
	}

	# title bar message
	echo "$MSG | color=$(colorize $AVG) $MENUFONT"
	echo "---"

	# dropdown details
	SITE_INDEX=0
	while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
		PING_TIME=${PING_TIMES[$SITE_INDEX]}
		if [ $PING_TIME -eq $MAX_PING ]; then
			PING_TIME="❌"
		else
			PING_TIME="$PING_TIME ms | color=$(colorize $PING_TIME) $FONT"
		fi

		echo "${SITES[$SITE_INDEX]}: $PING_TIME"
		SITE_INDEX=$(( SITE_INDEX + 1 ))
	done

	echo "---"
	echo "Refresh... | refresh=true"
}

function display-net-info {

	# ##################################################################################################
	# <bitbar.title>Network Info</bitbar.title>
	# <bitbar.version>v1.01</bitbar.version>
	# <bitbar.author>Raymond Kuiper</bitbar.author>
	# <bitbar.author.github>q1x</bitbar.author.github>
	# <bitbar.desc>Provides network status information about your Mac: Internal and external IPv4+IPv6 addresses, Whois information and Speedtest.net results.</bitbar.desc>
	# <bitbar.dependencies>speedtest-cli</bitbar.dependencies>
	# <bitbar.image>http://i.imgur.com/zFv3RvI.png</bitbar.image>
	#
	#
	# This bitbar plugin was based on the original "external-ip" Bitbar plugin by Mat Ryer.
	# A lot of new functionality has been added, including adding support for speedtest.net and listing internal interface information.
	#
	# Set path and Speedtest tmp file
	# PATH=/usr/local/bin:$PATH
	# SPEEDTEST="/tmp/speedtest.txt"


	# Function to notify the user via Aple Script
	# notify () {
	#     osascript -e "display notification \"$1\" with title \"Netinfo\""
	# }

	# If called with parameter "copy", copy the second parameter to the clipboard
	if [ "$1" = "copy" ]; then
	# Copy to clipboard
	echo "$2" | pbcopy
	notify "Copied $2 to clipboard"
	exit 0
	fi

	# If called with parameter "speedtest", run speedtest-cli
	# if [ "$1" = "speedtest" ]; then
	#   # test if speedtest-cli is found
	#   if [[ "$(which speedtest-cli)" != "" ]]; then
	#     # Perform a speedtest
	#     if speedtest-cli --simple --share > "$SPEEDTEST"; then
	#       notify "Speedtest is finished"
	#     else
	#       notify "Speedtest failed"
	#     fi
	#   else
	#      notify "Speedtest-cli not found!"
	#   fi
	#   exit 0
	# fi

	# Get external IPs
	EXTERNAL_IP4=$(curl -4 --connect-timeout 3 -s http://v4.ipv6-test.com/api/myip.php || echo None)
	EXTERNAL_IP6=$(curl -6 --connect-timeout 3 -s http://v6.ipv6-test.com/api/myip.php || echo None)

	# Perform whois lookup on the external IPv4 address.
	#[[ "$EXTERNAL_IP4" == "None" ]] && WHOIS="" || WHOIS=$(whois "$EXTERNAL_IP4" | awk '/descr: / {$1=""; print $0 }' | head -n 1)

	# Find interfaces
	INTERFACES=$(ifconfig | grep UP | egrep -o '(^en[0-9]*|^utun[0-9]*)' | sort -n)

	# Start building output
	# [[ "$EXTERNAL_IP4" == "None" && "$EXTERNAL_IP6" == "None" ]]  && echo "❌" || echo "🌐"
	#echo "---"
	#echo "🔄 Refresh | colo=black refresh=true"
	echo "---"
	echo "Public: "
	echo "IPv4: ${EXTERNAL_IP4}${WHOIS} | terminal=false bash='$0' param1=copy param2=$EXTERNAL_IP4"
	echo "IPv6: ${EXTERNAL_IP6} | terminal=false bash='$0' param1=copy param2=$EXTERNAL_IP6"
	# echo "---"
	#echo "📈 Perform Speedtest | terminal=false refresh=true bash='$0' param1=speedtest"

	# Pretty format the last speedtest if the tmp file is found
	# if [[ -e "$SPEEDTEST" ]]; then
	#      LAST=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$SPEEDTEST")
	#      PING=$(awk '/Ping: / { $1=""; print $0 }' "$SPEEDTEST")
	#      UP=$(awk '/Upload: / { $1=""; print $0 }' "$SPEEDTEST")
	#      DOWN=$(awk '/Download: / { $1=""; print $0 }' "$SPEEDTEST")
	#      LINK=$(awk '/Share results: / { $1=""; $2=""; print $0 }' "$SPEEDTEST")
	#      echo "Last checked: $LAST"
	#      [[ "$PING" != "" ]] && echo "⏱$PING ▼$DOWN ▲$UP | href=$LINK"|| echo "No results..."
	# else
	#      echo "Last checked: Never"
	# fi

	# Loop through the interfaces and output MAC, IPv4 and IPv6 information
	echo "---"
	for INT in $INTERFACES; do
		echo "$INT:"
		ifconfig "$INT" | awk "/ether/ { print \"MAC: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 }; /inet / { print \"IPv4: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 };  /inet6/ { print \"IPv6: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 }" | sed -e 's/%utun[0-9]*//g' -e 's/%en[0-9]*//g' | sort
		echo "---"

		# delete this if want to see all interfaces
		break
	done

}

# ##################################################################################################
# <bitbar.title>Got Internet?</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Federico Brigante</bitbar.author>
# <bitbar.author.github>bfred-it</bitbar.author.github>
# <bitbar.desc>Checks the connection to Internet and tells you in a single character.</bitbar.desc>
# <bitbar.image>http://i.imgur.com/I8lF8st.png</bitbar.image>

ping_timeout=1 #integers only, ping's fault
ping_address=8.8.8.8

if ! ping -c 1 -t $ping_timeout -q $ping_address > /dev/null 2>&1; then
	echo "❌|color=#f23400 dropdown=false"
	echo "---"
	echo "Offline"
	# echo "Ping to Google DNS failed"
else
	# echo "✦|dropdown=false"
	# echo "---"
	# echo "Online"
	display-ping
	display-net-info
fi
# EoF