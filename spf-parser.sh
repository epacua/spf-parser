#!/usr/bin/env bash

# commit 9fcd50d12213aee377ad6e5381f14e61261caa1e
# Author: Erwin Pacua <erwin.pacua@gmail.com
# Date:   Tue Apr 09 13:13:16 2019 +1300
# 
#     [Initial commit]

PRIMARY_DOMAIN=$1
REDIRECT=()
PTR=()
DOMAINS=()
IPS=()
A=()
INCLUDES=()
SPF=$(dig +short TXT $1 | grep 'v=spf')
get_domains(){
	DIG=( $(dig +short -t TXT -f <(echo $@) | grep 'v=spf' | grep -oi '\<\(\(a\|mx\)\|\(\(redirect=\|\(\(a\|mx\|include\|ptr\):\)\)[[:alnum:]._-]\+\)\|ip4:[0-9.]\+\(/[0-9]\{1,2\}\)\?\)\>') )
	local domain=()
	local redirect=()

	if [[ -n ${DIG[@]} ]]; then
		for ((i=0; i<${#DIG[@]}; i++)){
			[[ ${DIG[i]} =~ "include:" ]] && domain+=( ${DIG[i]##include:} ) && INCLUDES+=( ${DIG[i]##include:} )
			[[ ${DIG[i]} =~ "ptr:" ]] && PTR+=( ${DIG[i]##ptr:} )
			[[ ${DIG[i]} =~ "redirect=" ]] && redirect+=( ${DIG[i]##redirect=} ) && REDIRECT+=( ${DIG[i]##redirect=} )
			[[ ${DIG[i]} =~ "a" ]] && IPS+=( $(dig +short -tA $PRIMARY_DOMAIN) )
			[[ ${DIG[i]} =~ "mx" ]] && domain+=( $(dig +short -tMX $PRIMARY_DOMAIN | cut -d' ' -f2) )
			[[ ${DIG[i]} =~ "a:" ]] && IPS+=( $(dig +short -tA $i) )
			[[ ${DIG[i]} =~ "mx:" ]] && domain+=( $(dig +short -tMX $i | cut -d' ' -f2) )
			[[ ${DIG[i]} =~ "ip4:" ]] && IPS+=( ${DIG[i]##ip4:} )
		}
	else
		return
	fi
	DOMAINS+=( $(echo ${domain[@]}) )
	IPS+=( $(echo ${ip[@]}) )
	get_domains ${domain[@]} ${redirect[@]}
	unset DIG domain redirect
}
get_domains $@

echo "DOMAINS: ${DOMAINS[@]}"
IPS+=( $(echo $(dig +short -tA -f <(echo ${DOMAINS[@]}))) )
echo -e "\nCurrent SPF: $SPF"
echo -e "-------------------------------------------------------------------------------------------------"
[[ ${#INCLUDES[@]} -gt 0 ]] && echo -e "\nTOTAL 'include' mechanism: ${#INCLUDES[@]}\n\t${INCLUDES[@]}"
[[ ${#REDIRECT[@]} -gt 0 ]] &&  echo -e "\nTOTAL 'redirect' mechanism: ${#REDIRECT[@]}\n\t${REDIRECT[@]}"
[[ ${#PTR[@]} -gt 0 ]] &&  echo -e "\nTOTAL 'ptr' mechanism: ${#PTR[@]} -- ${PTR[@]}\n\tAny domains that ends with these are allowed to send."
echo -e "\nALLOWED IPs: ${#IPS[@]}"
echo -e "+-----------------------------------------------------------------------------------------------+"

for ((i=0; i<${#IPS[@]};)) {
	for ((x=0; x<4; x++)) {
		printf "%-1s %-18s %-18s %-18s %-18s %-18s%+1s\n" "|" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "|"
	}
}
echo -e "+===============================================================================================+"
echo -e "Thank you for using this program!\n"
