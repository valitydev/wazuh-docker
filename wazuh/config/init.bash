#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

# Initialize the custom data directory layout
source /data_dirs.env

cd /var/ossec
for ossecdir in "${DATA_DIRS[@]}"; do
  mkdir -p "data/${ossecdir}"
  mv ${ossecdir} data/${ossecdir}
  ln -s $(realpath --relative-to=$(dirname ${ossecdir}) data)/${ossecdir} ${ossecdir}
done
