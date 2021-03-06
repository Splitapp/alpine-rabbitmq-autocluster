FROM alpine:3.12

# Version of RabbitMQ to install
ENV RABBITMQ_VERSION=3.8.8
ENV AUTOCLUSTER_VERSION=3.8.8
ENV DELAYED_MESSAGE_VERSION=3.8.0
ENV MESSAGE_TIMESTAMP_VERSION=3.8.0
#ENV TOP_VERSION=3.6.x-2d253d39

RUN \
  apk --update add bash coreutils curl erlang  xz && \
  curl -sL -o /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz https://github.com/rabbitmq/rabbitmq-server/releases/download/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
  cd /usr/lib/ && \
  tar xf /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  rm /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  mv /usr/lib/rabbitmq_server-${RABBITMQ_VERSION} /usr/lib/rabbitmq

RUN \
  curl -sL -o /usr/lib/rabbitmq/plugins/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_VERSION}.ez  https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_MESSAGE_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_MESSAGE_VERSION}.ez && \
  curl -sL -o /usr/lib/rabbitmq/plugins/rabbitmq_message_timestamp-${MESSAGE_TIMESTAMP_VERSION}.ez https://github.com/rabbitmq/rabbitmq-message-timestamp/releases/download/v${MESSAGE_TIMESTAMP_VERSION}/rabbitmq_message_timestamp-${MESSAGE_TIMESTAMP_VERSION}.ez && \
  #curl -sL -o /usr/lib/rabbitmq/plugins/rabbitmq_top-${TOP_VERSION}.ez http://www.rabbitmq.com/community-plugins/${PLUGIN_BASE}/rabbitmq_top-${TOP_VERSION}.ez && \
  curl -sL -o /tmp/autocluster-${AUTOCLUSTER_VERSION}.tar.gz https://github.com/rabbitmq/rabbitmq-peer-discovery-aws/archive/v${AUTOCLUSTER_VERSION}.tar.gz && \
  tar -xvz -C /usr/lib/rabbitmq -f /tmp/autocluster-${AUTOCLUSTER_VERSION}.tar.gz && \
  rm /tmp/autocluster-${AUTOCLUSTER_VERSION}.tar.gz

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -s /bin/bash -D -h /var/lib/rabbitmq rabbitmq

ADD erlang.cookie /var/lib/rabbitmq/.erlang.cookie
ADD rabbitmq.conf /usr/lib/rabbitmq/etc/rabbitmq/rabbitmq.conf

# Environment variables required to run
ENV ERL_EPMD_PORT=4369
ENV HOME /var/lib/rabbitmq
ENV PATH /usr/lib/rabbitmq/bin:/usr/lib/rabbitmq/sbin:$PATH

ENV RABBITMQ_LOGS=-
ENV RABBITMQ_SASL_LOGS=-
ENV RABBITMQ_DIST_PORT=25672
ENV RABBITMQ_SERVER_ERL_ARGS="+K true +A128 +P 1048576 -kernel inet_default_connect_options [{nodelay,true}]"
ENV RABBITMQ_MNESIA_DIR=/var/lib/rabbitmq/mnesia
ENV RABBITMQ_PID_FILE=/var/lib/rabbitmq/rabbitmq.pid
ENV RABBITMQ_PLUGINS_DIR=/usr/lib/rabbitmq/plugins
ENV RABBITMQ_PLUGINS_EXPAND_DIR=/var/lib/rabbitmq/plugins

# Fetch the external plugins and setup RabbitMQ
RUN \
  apk --purge del curl tar gzip xz && \
  chown rabbitmq /var/lib/rabbitmq/.erlang.cookie /var/lib/rabbitmq /usr/lib/rabbitmq && \
  chmod 0600 /var/lib/rabbitmq/.erlang.cookie && \
  rabbitmq-plugins enable --offline \
        rabbitmq_peer_discovery_aws \
        rabbitmq_delayed_message_exchange \
        rabbitmq_management \
#        rabbitmq_management_visualiser \
        rabbitmq_consistent_hash_exchange \
        rabbitmq_federation \
        rabbitmq_federation_management \
        rabbitmq_message_timestamp \
        rabbitmq_mqtt \
        rabbitmq_recent_history_exchange \
        rabbitmq_sharding \
        rabbitmq_shovel \
        rabbitmq_shovel_management \
        rabbitmq_stomp \
        rabbitmq_top \
        rabbitmq_web_stomp && \
  rabbitmq-plugins list

EXPOSE 4369 5671 5672 15672 25672

USER rabbitmq
CMD /usr/lib/rabbitmq/sbin/rabbitmq-server
