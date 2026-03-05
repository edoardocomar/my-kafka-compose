#!/bin/bash
set -e

# Environment variables that should be set by docker-compose:
# For zookeeper:
#   - NODE_ID: ZooKeeper myid (1, 2, 3)
#   - PROCESS_ROLE: "zookeeper"
# For broker:
#   - NODE_ID: Kafka broker.id (0, 1, 2)
#   - PROCESS_ROLE: "broker"
#   - ZOOKEEPER_CONNECT: comma-separated ZK connection string
#   - KAFKA_ADVERTISED_LISTENERS

KAFKA_HOME=/opt/kafka

echo "=========================================="
echo "Starting Kafka/ZooKeeper Node"
echo "Node ID: $NODE_ID"
echo "Process Role: $PROCESS_ROLE"
echo "=========================================="

if [ "$PROCESS_ROLE" = "zookeeper" ]; then
    ZK_DATA_DIR=/var/lib/zookeeper/data
    mkdir -p $ZK_DATA_DIR

    # Write myid file (required by ZooKeeper ensemble)
    echo "$NODE_ID" > $ZK_DATA_DIR/myid
    echo "ZooKeeper myid: $NODE_ID"

    CONFIG_FILE=$KAFKA_HOME/config/zookeeper-custom.cfg
    cat > $CONFIG_FILE <<EOF
dataDir=$ZK_DATA_DIR
clientPort=2181
EOF

    # Append custom properties from my-zookeeper.properties if it exists
    if [ -f /opt/kafka/config/my-zookeeper.properties ]; then
        echo "" >> $CONFIG_FILE
        echo "# Custom properties from my-zookeeper.properties" >> $CONFIG_FILE
        cat /opt/kafka/config/my-zookeeper.properties >> $CONFIG_FILE
        echo "Applied custom properties from my-zookeeper.properties"
    fi

    echo "ZooKeeper config:"
    echo "------------------------------------------"
    cat $CONFIG_FILE
    echo "------------------------------------------"

    exec $KAFKA_HOME/bin/zookeeper-server-start.sh $CONFIG_FILE

elif [ "$PROCESS_ROLE" = "broker" ]; then
    DATA_DIR=/var/lib/kafka/data
    mkdir -p $DATA_DIR

    CONFIG_FILE=$KAFKA_HOME/config/broker.properties
    cat > $CONFIG_FILE <<EOF
# Kafka Broker Configuration (ZooKeeper mode)
broker.id=$NODE_ID
zookeeper.connect=$ZOOKEEPER_CONNECT

# Listeners
listeners=INTERBROKER://:9092,EXTERNAL://:9093
advertised.listeners=$KAFKA_ADVERTISED_LISTENERS

# Log directories
log.dirs=$DATA_DIR
EOF

    # Append custom properties if file exists
    if [ -f /opt/kafka/config/my-broker-zk.properties ]; then
        echo "" >> $CONFIG_FILE
        echo "# Custom properties from my-broker-zk.properties" >> $CONFIG_FILE
        cat /opt/kafka/config/my-broker-zk.properties >> $CONFIG_FILE
        echo "Applied custom properties from my-broker-zk.properties"
    fi

    echo "Broker config:"
    echo "------------------------------------------"
    cat $CONFIG_FILE
    echo "------------------------------------------"

    echo "Starting Kafka broker..."
    if [ "$KAFKA_DEBUG" = "true" ]; then
        echo "Debug mode will be enabled on port 5005"
    fi
    exec $KAFKA_HOME/bin/kafka-server-start.sh $CONFIG_FILE

else
    echo "ERROR: PROCESS_ROLE must be 'zookeeper' or 'broker'"
    exit 1
fi
