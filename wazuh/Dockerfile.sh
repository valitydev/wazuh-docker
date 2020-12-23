#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)
cat <<EOF
FROM phusion/baseimage:bionic-1.0.0

ARG FILEBEAT_VERSION=6.8.1
ARG WAZUH_VERSION=3.12.3-1
ARG HIVE4PY_VERSION=1.6.0

ENV WAZUH_FILEBEAT_MODULE=wazuh-filebeat-0.1.tar.gz

ENV API_USER="foo" \
    API_PASS="bar"

ARG TEMPLATE_VERSION="v3.12.3"

# Set repositories.
RUN apt update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt -y install curl apt-transport-https lsb-release gnupg2 software-properties-common && \
    set -x && echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    curl --silent --location https://deb.nodesource.com/setup_10.x | bash - && \
    groupadd -g 1000 ossec && useradd -u 1000 -g 1000 -d /var/ossec ossec

RUN add-apt-repository universe && apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get --no-install-recommends --no-install-suggests -y install openssl python-boto python-pip python-setuptools \
    apt-transport-https vim expect nodejs python-cryptography libsasl2-modules wazuh-manager=\${WAZUH_VERSION} \
    wazuh-api=\${WAZUH_VERSION} && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && rm -f \
    /var/ossec/logs/alerts/*/*/*.log && rm -f /var/ossec/logs/alerts/*/*/*.json && rm -f \
    /var/ossec/logs/archives/*/*/*.log && rm -f /var/ossec/logs/archives/*/*/*.json && rm -f \
    /var/ossec/logs/firewall/*/*/*.log && rm -f /var/ossec/logs/firewall/*/*/*.json

# Install Wazuh Filebeat Module

RUN mkdir -p /usr/share/filebeat/module/wazuh && \
    curl -s "https://packages.wazuh.com/3.x/filebeat/\${WAZUH_FILEBEAT_MODULE}" | tar -xvz -C /usr/share/filebeat/module && \
    chmod 755 -R /usr/share/filebeat/module/wazuh

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-\${FILEBEAT_VERSION}-amd64.deb && \
    dpkg -i filebeat-oss-\${FILEBEAT_VERSION}-amd64.deb && rm -f filebeat-oss-\${FILEBEAT_VERSION}-amd64.deb

RUN curl -sL https://raw.githubusercontent.com/wazuh/wazuh/\$TEMPLATE_VERSION/extensions/elasticsearch/6.x/wazuh-template.json -o /etc/filebeat/wazuh-template.json && \
    sed -i 's@"wazuh":@"doc":@' /etc/filebeat/wazuh-template.json && \
    chmod go-w /etc/filebeat/wazuh-template.json

# Adding first run script and entrypoint
COPY config/data_dirs.env /data_dirs.env
COPY config/init.bash /init.bash
RUN mkdir /entrypoint-scripts
COPY config/entrypoint.sh /entrypoint.sh
COPY config/00-wazuh.sh /entrypoint-scripts/00-wazuh.sh

# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /entrypoint.sh && \
    chmod 755 /entrypoint-scripts/00-wazuh.sh

COPY config/filebeat.yml /etc/filebeat/
RUN chmod go-w /etc/filebeat/filebeat.yml

# Setting volumes

VOLUME ["/etc/filebeat"]
VOLUME ["/var/lib/filebeat"]
VOLUME ["/var/log/filebeat/"]
VOLUME ["/var/ossec/data/logs/"]
VOLUME ["/wazuh-config-mount"]

# Services ports
EXPOSE 514/udp 1514/udp 1514/tcp 1515/tcp 1516/tcp 55000/tcp

# Adding services
RUN mkdir -p /etc/service/wazuh && \
    mkdir /etc/service/wazuh-api && \
    mkdir /etc/service/filebeat

COPY config/wazuh.runit.service /etc/service/wazuh/run
COPY config/wazuh-api.runit.service /etc/service/wazuh-api/run
COPY config/filebeat.runit.service /etc/service/filebeat/run
COPY config/apps/* /var/ossec/bin/

RUN chmod +x /etc/service/wazuh-api/run /etc/service/wazuh/run \
             /etc/service/filebeat/run /var/ossec/bin/*

COPY --chown=root:ossec config/integrations/* /var/ossec/integrations/

RUN chmod 755 /var/ossec/integrations/* && \
    pip install thehive4py==\${HIVE4PY_VERSION}

# Run all services
ENTRYPOINT ["/entrypoint.sh"]
EOF
