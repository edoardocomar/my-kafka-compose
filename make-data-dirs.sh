#!/bin/bash
set -e

echo "Creating data directories for all clusters..."

# KRaft cluster (Kafka 4.2.0)
mkdir -p data/v4.2.0-KRaft/controller-1000 \
         data/v4.2.0-KRaft/controller-1001 \
         data/v4.2.0-KRaft/controller-1002 \
         data/v4.2.0-KRaft/broker-0 \
         data/v4.2.0-KRaft/broker-1 \
         data/v4.2.0-KRaft/broker-2

# ZooKeeper mode cluster (Kafka 3.9.2)
mkdir -p data/v3.9.2-ZKmode/zookeeper-1 \
         data/v3.9.2-ZKmode/zookeeper-2 \
         data/v3.9.2-ZKmode/zookeeper-3 \
         data/v3.9.2-ZKmode/zk-broker-0 \
         data/v3.9.2-ZKmode/zk-broker-1 \
         data/v3.9.2-ZKmode/zk-broker-2

tree data