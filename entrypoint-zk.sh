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
tickTime=2000
initLimit=10
syncLimit=5
dataDir=$ZK_DATA_DIR
clientPort=2181

# ZooKeeper ensemble members
server.1=zookeeper-1:2888:3888
server.2=zookeeper-2:2888:3888
server.3=zookeeper-3:2888:3888
EOF

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
listener.security.protocol.map=INTERBROKER:PLAINTEXT,EXTERNAL:PLAINTEXT
inter.broker.listener.name=INTERBROKER

# Log directories
log.dirs=$DATA_DIR

# Replication settings
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
default.replication.factor=3
min.insync.replicas=2

# Other settings
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
num.partitions=3
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
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
