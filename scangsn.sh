#!/bin/sh

#
# scangsn.sh
#

HOSTS_CSV="https://scrapbox.io/api/table/Geek-SpaceBox/GSNet%E3%81%AE%E3%83%9B%E3%82%B9%E3%83%88%E4%B8%80%E8%A6%A7/hosts.csv"

curl -s "${HOSTS_CSV}" |
  sed 1d |
  cut -d ',' -f 2 |
  tr -d '[]' |
  ./pping |
  grep '. packets transmitted, . \(packets \)*received'  |
  cut -d ' ' -f 1,3- |
  sort -t '.' -k 1,1n -k 2,2n -k 3,3n -k 4n |
  while IFS='' read -r l; do
    if echo "${l}" | grep ' 0\(\.0\)*% packet loss' > /dev/null; then
      printf '\e[32m%s\e[m\n' "${l}"
    elif echo "${l}" | grep ' 100\(\.0\)*% packet loss' > /dev/null; then
      printf '\e[31m%s\e[m\n' "${l}"
    else
      printf '\e[33m%s\e[m\n' "${l}"
    fi
  done
