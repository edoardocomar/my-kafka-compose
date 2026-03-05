# my-kafka-compose

Two independent Kafka cluster setups in Docker Compose, each built from a local `.tgz`:

KRaft v4.2.0 : 3 controllers + 3 brokers using `docker-compose.yml`

ZooKeeper-mode v3.9.2: 3 ZooKeeper nodes + 3 brokers using `docker-compose-zk.yml` |

**Note:**
Data is stored in `./data/` subdirectories

To start fresh, delete the `./data/` directory before starting.

**Source Debugging**

Set `KAFKA_DEBUG: "true"` in `docker-compose.yml` (or -zk) to enable JDWP on port 5005.

### Start

```bash
# Create data directories (first time only)
./make-data-dirs.sh

# Remove old containers (data persists in ./data/)
docker compose down
# or
docker compose -f docker-compose-zk.yml down

# Build and start
docker compose up -d --build
# or
docker compose -f docker-compose-zk.yml up -d --build

# Verify: should see 6 containers (3 controllers + 3 brokers), all "healthy"
docker compose ps

# Verify: should see 6 containers (3 ZooKeepers + 3 brokers), all "healthy"
docker compose -f docker-compose-zk.yml ps
```

### Restart options

```bash
# Restart only brokers (keeps data)
docker compose restart broker-0 broker-1 broker-2
# or
docker compose -f docker-compose-zk.yml restart broker-0 broker-1 broker-2

# Full restart (clean state)
docker compose down && docker compose up -d
# or
docker compose -f docker-compose-zk.yml down && docker compose -f docker-compose-zk.yml up -d
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
# KRaft based
bin/kafka-topics.sh --bootstrap-server localhost:19092,localhost:19093,localhost:19094 --describe
```

```bash
# ZK based
bin/kafka-topics.sh --bootstrap-server localhost:29092,localhost:29093,localhost:29094 --describe
```


### JConsole

```bash
# KRaft-mode
jconsole localhost:20000  # controller-1000
jconsole localhost:20001  # controller-1001
jconsole localhost:20002  # controller-1002
jconsole localhost:19990  # broker-0
jconsole localhost:19991  # broker-1
jconsole localhost:19992  # broker-2
```
```bash
# zk-mode
jconsole localhost:29990  # zk-broker-0
jconsole localhost:29991  # zk-broker-1
jconsole localhost:29992  # zk-broker-2
```

## Data Storage

All Kafka and ZooKeeper data is stored in workspace subdirectories under `./data/`.
The `./data/` directory is excluded from git via `.gitignore`.

```
data
├── v3.9.2-ZKmode
│   ├── zk-broker-0
│   ├── zk-broker-1
│   ├── zk-broker-2
│   ├── zookeeper-1
│   ├── zookeeper-2
│   └── zookeeper-3
│  
└── v4.2.0-KRaft
    ├── broker-0
    ├── broker-1
    ├── broker-2
    ├── controller-1000
    ├── controller-1001
    └── controller-1002
```


## Docker Cleanup

| Command | What it removes |
|---|---|
| `docker image prune` | Only "dangling" images (named `<none>`) |
| `docker system prune` | Dangling images, stopped containers, unused networks |
| `docker system prune -a` | All images not used by a running container |
| `docker builder prune` | Only the build cache (layers from `docker build`) |
