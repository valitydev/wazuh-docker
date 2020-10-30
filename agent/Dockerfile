FROM ubuntu:bionic

RUN apt update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt -y install curl apt-transport-https lsb-release gnupg2 && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    apt update && \
    apt-get install wazuh-agent=3.12.3-1 && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./entrypoint.sh /entrypoint

RUN chmod +x /entrypoint

ENTRYPOINT [ "/entrypoint" ]
