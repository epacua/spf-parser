#!/usr/bin/env bash

# commit 9fcd50d12213aee377ad6e5381f14e61261caa1e
# Author: Erwin Pacua <erwin.pacua@gmail.com
# Date:   Tue Apr 09 13:13:16 2019 +1300
# 
#     [Initial commit]
#

if [[ ! $(which dig) ]]; then
  echo "The dns tool 'dig' is not found. Please install it and re-run"
  exit
fi

PRIMARY_DOMAIN=$1
REDIRECT=()
PTR=()
DOMAINS=()
IPS=()
A=()
INCLUDES=()
SPF=$(dig +short -tTXT $1 | grep 'v=spf')

get_domains(){
  DIG=( $(dig +short -tTXT -f <(echo $@) | grep 'v=spf' | grep -oi '\<\(\(a\|mx\)\|\(\(redirect=\|\(\(a\|mx\|include\|ptr\):\)\)[[:alnum:]._-]\+\)\|ip4:[0-9.]\+\(/[0-9]\{1,2\}\)\?\)\>') )
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
  unset i DIG domain redirect
}

build_report() {
  echo "DOMAINS: ${DOMAINS[@]}"
  echo "-------------------------------------------------------------------------------------------------"
  IPS+=( $(echo $(dig +short -tA -f <(echo ${DOMAINS[@]}))) )
  echo -e "\nCurrent SPF: $SPF"
  echo "-------------------------------------------------------------------------------------------------"

  if [[ ${#INCLUDES[@]} -gt 0 ]]; then
    echo -e "\nTOTAL 'include' mechanism: ${#INCLUDES[@]}\n\t${INCLUDES[@]}"
    echo "-------------------------------------------------------------------------------------------------"
  fi

  if [[ ${#REDIRECT[@]} -gt 0 ]]; then
    echo -e "\nTOTAL 'redirect' mechanism: ${#REDIRECT[@]}\n\t${REDIRECT[@]}"
    echo "-------------------------------------------------------------------------------------------------"
  fi

  if [[ ${#PTR[@]} -gt 0 ]]; then
    echo -e "\nTOTAL 'ptr' mechanism: ${#PTR[@]} -- ${PTR[@]}\n\t(Allowed to send from these domains.)"
    echo "-------------------------------------------------------------------------------------------------"
  fi

  echo -e "\nTOTAL ALLOWED IPs: ${#IPS[@]}"
  echo "+-----------------------------------------------------------------------------------------------+"

  # Iterate through all IP addresses
  for ((i=0; i<${#IPS[@]};)) {
    # Formatting helper
    for ((x=0; x<1; x++)) {
      printf "%-1s %-18s %-18s %-18s %-18s %-18s%+1s\n" "|" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "${IPS[$((i++))]}" "|"
    }
  }
  echo "+===============================================================================================+"

  echo -e "\nThank you for using this program!\n"
}

get_domains "$@"
build_report
