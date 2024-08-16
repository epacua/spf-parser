#!/usr/bin/env bash
set -o pipefail

# commit 9fcd50d12213aee377ad6e5381f14e61261caa1e
# Author: Erwin Pacua <erwin.pacua@gmail.com
# Date:   Tue Apr 09 13:13:16 2019 +1300
#
#     [Initial commit]
#

if [[ $# -ne 1 ]]; then
  echo "[ERROR] Please provide a domain name to check."
  exit 1
fi

if ! $(which dig); then
  echo "[ERROR] The dns tool 'dig' is not found. Please install it then re-run"
  exit
fi

primary_domain=$1
redirect=()
ptr=()
spf_domains=()
total_domains=()
ip4_list=($(dig +short -tA $primary_domain))
ip6_list=($(dig +short -tAAAA $primary_domain))
include_mechanism=()
spf_txtrr=$(dig +noall +short -tTXT $1 | grep 'v=spf')

get_domains() {
  dig_output=($(dig +noall +short -tTXT -f <(echo $@) | grep 'v=spf' | grep -oi \
    '\<\(\(a\|mx\)\|\(\(redirect=\|\(\(a\|mx\|include\|ptr\):\)\)[[:alnum:]._-]\+\)\|ip4:[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\(/[0-9]\{1,2\}\)\?\)\|ip6:[[:xdigit:]:]\{1,16\}\(/[[:digit:]]\{1,3\}\)\>'))

  local domain=()
  local redirect=()

  if [[ -n ${dig_output[@]} ]]; then
    for ((i = 0; i < ${#dig_output[@]}; i++)); do
      [[ ${dig_output[i]} =~ "include:" ]] && domain+=(${dig_output[i]##include:}) && include_mechanism+=(${dig_output[i]##include:})
      [[ ${dig_output[i]} =~ "ptr:" ]] && ptr+=(${dig_output[i]##ptr:})
      [[ ${dig_output[i]} =~ "redirect=" ]] && redirect+=(${dig_output[i]##redirect=}) && redirect+=(${dig_output[i]##redirect=})
      [[ ${dig_output[i]} =~ "mx" ]] && domain+=($(dig +short -tMX $primary_domain | cut -d' ' -f2))
      [[ ${dig_output[i]} =~ "a:" ]] && ip4_list+=($(dig +short -tA $i))
      [[ ${dig_output[i]} =~ "mx:" ]] && domain+=($(dig +short -tMX $i | cut -d' ' -f2))
      [[ ${dig_output[i]} =~ "ip4:" ]] && ip4_list+=(${dig_output[i]##ip4:})
      [[ ${dig_output[i]} =~ "ip6:" ]] && ip6_list+=(${dig_output[i]##ip6:})
    done
  else
    return
  fi

  spf_domains+=($(echo ${domain[@]}))
  ip4_list+=($(echo ${ip4_list[@]}))
  get_domains ${domain[@]} ${redirect[@]}
  unset i dig_output domain redirect
}

build_report() {
  if [[ ${#spf_domains[@]} -gt 0 ]]; then
    cat <<EOF
SPF Domains:
    ${spf_domains[@]}

SPF_TXT Resource Record
    $spf_txtrr

EOF
  fi

  if [[ ${#include_mechanism[@]} -gt 0 ]]; then
    cat <<EOF
TOTAL 'include' mechanism: ${#include_mechanism[@]}
    ${include_mechanism[@]}
EOF
  fi

  if [[ ${#redirect[@]} -gt 0 ]]; then
    cat <<EOF
TOTAL 'redirect' mechanism: ${#redirect[@]}\n\t${redirect[@]}
EOF
  fi

  if [[ ${#ptr[@]} -gt 0 ]]; then
    cat <<EOF
TOTAL 'ptr' mechanism: ${#ptr[@]} -- ${ptr[@]}
EOF
  fi

  echo -e "\nTOTAL ALLOWED IPv4 addresses: ${#ip4_list[@]}"
  echo "+----------------------------------------------------------------------------------------------------+"
  # Iterate through all IPv4 addresses
  for ((i = 0; i < ${#ip4_list[@]}; )); do
    printf "%-1s %-18s %-18s %-18s %-18s %-22s%1s\n" "|" "${ip4_list[$((i++))]}" "${ip4_list[$((i++))]}" "${ip4_list[$((i++))]}" "${ip4_list[$((i++))]}" "${ip4_list[$((i++))]}" " |"
  done
  echo "+====================================================================================================+"

  echo -e "\nTOTAL ALLOWED IPv6 addresses: ${#ip6_list[@]}"
  echo "+----------------------------------------------------------------------------------------------------+"

  # Iterate through all IPv6 addresses
  for ((i = 0; i < ${#ip6_list[@]}; )); do
    printf "%s\n" "${ip6_list[$((i++))]}"
  done
  echo "+====================================================================================================+"

  echo -e "\nThank you for using this program!"
}

get_domains "$@"
build_report
