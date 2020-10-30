#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

kibana_config_file="/usr/share/kibana/config/kibana.yml"
if grep -Fq  "#xpack features" "$kibana_config_file";
then
  declare -A CONFIG_MAP=(
  )
  for i in "${!CONFIG_MAP[@]}"
  do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
      sed -i 's/.'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $kibana_config_file
    fi
  done
else
  echo "
#xpack features
console.enabled: $XPACK_DEVTOOLS
" >> $kibana_config_file
fi
