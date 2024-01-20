#!/usr/bin/env bash
#CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PATH="/usr/local/bin:$PATH:/usr/sbin"

get_bandwidth_for_osx() {
  netstat -ibn | awk 'FNR > 1 {
    interfaces[$1 ":bytesReceived"] = $(NF-4);
    interfaces[$1 ":bytesSent"]     = $(NF-1);
  } END {
    for (itemKey in interfaces) {
      split(itemKey, keys, ":");
      interface = keys[1]
      dataKind = keys[2]
      sum[dataKind] += interfaces[itemKey]
    }

    print sum["bytesReceived"], sum["bytesSent"]
  }'
}

os_type() {
  local os_name="unknown"

  case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    os_name="linux"
    ;;
  darwin*)
    os_name="osx"
    ;;
  msys*)
    os_name="windows"
    ;;
  freebsd*)
    os_name="freebsd"
    ;;
  esac

  echo -n $os_name
}

get_bandwidth() {
  local os="$1"

  case $os in
  osx)
    echo -n $(get_bandwidth_for_osx)
    return 0
    ;;
  linux)
    echo -n $(get_bandwidth_for_linux)
    return 0
    ;;
  *)
    echo -n "0 0"
    return 1
    ;;
  esac
}

format_speed() {
  numfmt --to=iec-i --suffix "B/s" --format "%f" --padding 5 $1
}

main() {

  sleep_time=1

  if [[ -z $interval_update ]]; then
    interval_update=1
  fi

  while true; do

    os=$(os_type)
    first_measure=($(get_bandwidth "$os"))
    sleep $sleep_time
    second_measure=($(get_bandwidth "$os"))
    download_speed=$(((${second_measure[0]} - ${first_measure[0]}) / $sleep_time))
    upload_speed=$(((${second_measure[1]} - ${first_measure[1]}) / $sleep_time))
    echo "↓$(format_speed $download_speed)•↑$(format_speed $upload_speed)"

  done
}

#run main driver
main
