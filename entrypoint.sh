#!/bin/bash
set -e

# Environment variables that should be set by docker-compose:
# - NODE_ID: Unique identifier for this node
# - PROCESS_ROLE: Either "controller" or "broker"
# - CONTROLLER_QUORUM_VOTERS: List of controller nodes
# - CLUSTER_ID: Shared cluster UUID
# - KAFKA_ADVERTISED_LISTENERS: For brokers only

KAFKA_HOME=/opt/kafka
CONFIG_DIR=$KAFKA_HOME/config
DATA_DIR=/var/lib/kafka/data

echo "=========================================="
echo "Starting Kafka Node"
echo "Node ID: $NODE_ID"
echo "Process Role: $PROCESS_ROLE"
echo "=========================================="

# Create a custom server.properties based on role
if [ "$PROCESS_ROLE" = "controller" ]; then
    CONFIG_FILE=$CONFIG_DIR/controller.properties

    cat > $CONFIG_FILE <<EOF
# KRaft Controller Configuration
process.roles=controller
node.id=$NODE_ID
controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS

# Listeners
listeners=CONTROLLER://:9093
controller.listener.names=CONTROLLER

# Log directories
log.dirs=$DATA_DIR

# Metadata log configuration
metadata.log.dir=$DATA_DIR/metadata

# Internal topic settings
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
EOF

    # Append custom properties from my-controller.properties if it exists
    if [ -f /opt/kafka/config/my-controller.properties ]; then
        echo "" >> $CONFIG_FILE
        echo "# Custom properties from my-controller.properties" >> $CONFIG_FILE
        cat /opt/kafka/config/my-controller.properties >> $CONFIG_FILE
        echo "Applied custom properties from my-controller.properties"
    fi

elif [ "$PROCESS_ROLE" = "broker" ]; then
    CONFIG_FILE=$CONFIG_DIR/broker.properties

    cat > $CONFIG_FILE <<EOF
# KRaft Broker Configuration
process.roles=broker
node.id=$NODE_ID
controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS
controller.listener.names=CONTROLLER

# Listeners
listeners=INTERBROKER://:9092,EXTERNAL://:9093
advertised.listeners=$KAFKA_ADVERTISED_LISTENERS
listener.security.protocol.map=INTERBROKER:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT
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

    # Append custom properties from my-broker.properties if it exists
    if [ -f /opt/kafka/config/my-broker.properties ]; then
        echo "" >> $CONFIG_FILE
        echo "# Custom properties from my-broker.properties" >> $CONFIG_FILE
        cat /opt/kafka/config/my-broker.properties >> $CONFIG_FILE
        echo "Applied custom properties from my-broker.properties"
    fi
else
    echo "ERROR: PROCESS_ROLE must be either 'controller' or 'broker'"
    exit 1
fi

echo "Configuration file created at: $CONFIG_FILE"
echo "------------------------------------------"
cat $CONFIG_FILE
echo "------------------------------------------"

# Format storage if not already formatted
if [ ! -f $DATA_DIR/.formatted ]; then
    echo "Formatting storage with cluster ID: $CLUSTER_ID"
    $KAFKA_HOME/bin/kafka-storage.sh format \
        -t $CLUSTER_ID \
        -c $CONFIG_FILE

    touch $DATA_DIR/.formatted
    echo "Storage formatted successfully"
else
    echo "Storage already formatted, skipping format step"
fi

# Wait a bit for controllers to be ready if this is a broker
if [ "$PROCESS_ROLE" = "broker" ]; then
    echo "Waiting 10 seconds for controllers to be ready..."
    sleep 10
fi

# Start Kafka
# Note: kafka-server-start.sh will automatically enable debug mode
# if KAFKA_DEBUG env var is set, using KAFKA_DEBUG_OPTS
echo "Starting Kafka server..."
if [ "$KAFKA_DEBUG" = "true" ]; then
    echo "Debug mode will be enabled on port 5005"
fi
exec $KAFKA_HOME/bin/kafka-server-start.sh $CONFIG_FILE

# Made with Bob
