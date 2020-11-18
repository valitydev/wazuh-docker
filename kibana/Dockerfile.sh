#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)
cat <<EOF
FROM centos:7 as plugin_builder

ARG KIBANA_PLUGIN_VERSION="v3.12.3-6.8.1"

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    curl -sL https://rpm.nodesource.com/setup_8.x | bash - && \
    yum install git nodejs -y && \
    npm install -g n

ADD ./config/build.sh /
RUN chmod +x /build.sh && \
    mkdir /wazuh_app /source && \
    /build.sh \${KIBANA_PLUGIN_VERSION}

FROM docker.elastic.co/kibana/kibana-oss:6.8.1
USER kibana
ARG ELASTIC_VERSION=6.8.1
ARG WAZUH_VERSION=3.12.3
ARG WAZUH_APP_VERSION="\${WAZUH_VERSION}_\${ELASTIC_VERSION}"

COPY --from=plugin_builder /wazuh_app/wazuh_kibana-*.zip /tmp/wazuh_kibana.zip

WORKDIR /usr/share/kibana
RUN ./bin/kibana-plugin install file:///tmp/wazuh_kibana.zip

WORKDIR /
USER root
COPY config/entrypoint.sh ./entrypoint.sh
RUN chmod 755 ./entrypoint.sh

ENV PATTERN="" \
    CHECKS_PATTERN="" \
    CHECKS_TEMPLATE="" \
    CHECKS_API="" \
    CHECKS_SETUP="" \
    EXTENSIONS_PCI="" \
    EXTENSIONS_GDPR="" \
    EXTENSIONS_AUDIT="" \
    EXTENSIONS_OSCAP="" \
    EXTENSIONS_CISCAT="" \
    EXTENSIONS_AWS="" \
    EXTENSIONS_VIRUSTOTAL="" \
    EXTENSIONS_OSQUERY="" \
    APP_TIMEOUT="" \
    WAZUH_SHARDS="" \
    WAZUH_REPLICAS="" \
    WAZUH_VERSION_SHARDS="" \
    WAZUH_VERSION_REPLICAS="" \
    IP_SELECTOR="" \
    IP_IGNORE="" \
    XPACK_RBAC_ENABLED="" \
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS="" \
    ADMIN_PRIVILEGES=""

ARG XPACK_CANVAS="true"
ARG XPACK_LOGS="true"
ARG XPACK_INFRA="true"
ARG XPACK_ML="true"
ARG XPACK_DEVTOOLS="true"
ARG XPACK_MONITORING="true"
ARG XPACK_APM="true"

ARG CHANGE_WELCOME="false"

COPY --chown=kibana:kibana ./config/wazuh_app_config.sh ./

RUN chmod +x ./wazuh_app_config.sh

COPY --chown=kibana:kibana ./config/kibana_settings.sh ./

RUN chmod +x ./kibana_settings.sh

COPY --chown=kibana:kibana ./config/xpack_config.sh ./

RUN chmod +x ./xpack_config.sh

RUN ./xpack_config.sh

COPY --chown=kibana:kibana ./config/welcome_wazuh.sh ./

RUN chmod +x ./welcome_wazuh.sh

RUN ./welcome_wazuh.sh
USER kibana
RUN NODE_OPTIONS="--max-old-space-size=2048" /usr/local/bin/kibana-docker --optimize

ENTRYPOINT ./entrypoint.sh
EOF
