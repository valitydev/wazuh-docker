#!/bin/bash

. /etc/ossec-init.conf

echo "Agent init script require WAZUH_MANAGER env variable to be set. AGENT_REG_PASS env variable is optional"

if [ -n "$AGENT_REG_PASS" ]; then
  echo "$AGENT_REG_PASS" > ${DIRECTORY}/etc/authd.pass
fi

if [ -n "$WAZUH_MANAGER" ]; then
  ${DIRECTORY}/bin/agent-auth -m wazuh || (echo Agent registration failed && exit 1)
else
  echo Please set WAZUH_MANAGER ip or host
  exit 1
fi

sed -i "s@<address>.*</address>@<address>${WAZUH_MANAGER}</address>@" ${DIRECTORY}/etc/ossec.conf
${DIRECTORY}/bin/ossec-control start

AGENT_PID="$(pidof ${DIRECTORY}/bin/ossec-agentd)"

if [ -n "$AGENT_PID" ]; then
  tail --pid=$AGENT_PID -f ${DIRECTORY}/logs/ossec.log
else
  echo "Agent won't start"
  cat ${DIRECTORY}/logs/ossec.log
  exit 1
fi
