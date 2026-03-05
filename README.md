# my-kafka-compose

Two independent Kafka cluster setups in Docker Compose, each built from a local `.tgz`:

| Cluster | Kafka version | Mode | Compose file |
|---|---|---|---|
| KRaft | 4.2.0 | 3 controllers + 3 brokers (no ZooKeeper) | `docker-compose.yml` |
| ZooKeeper | 3.9.2 | 3 ZooKeeper nodes + 3 brokers | `docker-compose-zk.yml` |

---

## KRaft Cluster (Kafka 4.2.0)

### Start

```bash
# Remove old containers and volumes
docker compose down -v

# Build and start
docker compose up -d --build

# Verify: should see 6 containers (3 controllers + 3 brokers), all "healthy"
docker compose ps
```

### Restart options

```bash
# Restart only brokers (keeps data)
docker compose restart broker-0 broker-1 broker-2

# Full restart (clean state)
docker compose down && docker compose up -d
```

### Ports

| Service | External Kafka | JMX | Debug |
|---|---|---|---|
| controller-1000 | — | 20000 | 5000 |
| controller-1001 | — | 20001 | 5001 |
| controller-1002 | — | 20002 | 5002 |
| broker-0 | 19092 | 19990 | 5010 |
| broker-1 | 19093 | 19991 | 5011 |
| broker-2 | 19094 | 19992 | 5012 |

### Access from macOS

```bash
kafka-topics.sh --bootstrap-server localhost:19092,localhost:19093,localhost:19094 --list
```

### JConsole

```bash
jconsole localhost:20000  # controller-1000
jconsole localhost:20001  # controller-1001
jconsole localhost:20002  # controller-1002
jconsole localhost:19990  # broker-0
jconsole localhost:19991  # broker-1
jconsole localhost:19992  # broker-2
```

### Source Debugging

Set `KAFKA_DEBUG: "true"` in `docker-compose.yml` to enable JDWP on port 5005.

---

## ZooKeeper Cluster (Kafka 3.9.2)

### Start

```bash
# Remove old containers and volumes
docker compose -f docker-compose-zk.yml down -v

# Build and start
docker compose -f docker-compose-zk.yml up -d --build

# Verify: should see 6 containers (3 ZooKeepers + 3 brokers), all "healthy"
docker compose -f docker-compose-zk.yml ps
```

### Restart options

```bash
# Restart only brokers (keeps data)
docker compose -f docker-compose-zk.yml restart broker-0 broker-1 broker-2

# Full restart (clean state)
docker compose -f docker-compose-zk.yml down && docker compose -f docker-compose-zk.yml up -d
```

### Ports

| Service | External port | JMX | Debug |
|---|---|---|---|
| zookeeper-1 | 12181 (client) | — | — |
| zookeeper-2 | 12182 (client) | — | — |
| zookeeper-3 | 12183 (client) | — | — |
| broker-0 | 29092 | 29990 | 5010 |
| broker-1 | 29093 | 29991 | 5011 |
| broker-2 | 29094 | 29992 | 5012 |

### Access from macOS

```bash
kafka-topics.sh --bootstrap-server localhost:29092,localhost:29093,localhost:29094 --list
```

### JConsole

```bash
jconsole localhost:29990  # broker-0
jconsole localhost:29991  # broker-1
jconsole localhost:29992  # broker-2
```

### Source Debugging

Set `KAFKA_DEBUG: "true"` in `docker-compose-zk.yml` to enable JDWP on port 5005.

---

## Access Docker Desktop VM on macOS

```bash
# Access the Docker Desktop VM directly
docker run -it --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh
```

Once inside:

```bash
cd /var/lib/docker/volumes
ls -la
# KRaft: broker-0-data, controller-1000-data, etc.
# ZooKeeper: zk-broker-0-data, zookeeper-1-data, etc.
```

## Docker Cleanup

| Command | What it removes |
|---|---|
| `docker image prune` | Only "dangling" images (named `<none>`) |
| `docker system prune` | Dangling images, stopped containers, unused networks |
| `docker system prune -a` | All images not used by a running container |
| `docker builder prune` | Only the build cache (layers from `docker build`) |
