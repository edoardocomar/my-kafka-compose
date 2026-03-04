# my-kafka-compose

Start up a 3 broker 3 controller cluster in docker compose using a local kafka*tgz


## Start the Cluster

```bash
# 1. Remove old containers and volumes
docker-compose down -v

# 2. Rebuild images (will create edokafka-controller-1000, edokafka-broker-0, etc.)
docker-compose build

# 3. Start the cluster
docker-compose up -d

# 4. Verify all services
# Should see 6 containers: 3 controllers and 3 brokers, all "healthy"
docker-compose ps

# 5. Check new image names
docker images | grep edokafka

# Stop all containers (preserves data)
docker-compose stop

# Or stop and remove containers (preserves data volumes)
docker-compose down

```

Wait for all services to show "started" in the logs (approximately 30-60 seconds).

### Restart options

1. **Restart only the brokers** (recommended - keeps data)
   ```bash
   docker-compose restart broker-0 broker-1 broker-2
   ```

2. **Or restart everything** (if you need a clean state)
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Using JConsole:

```bash
# Controllers
jconsole localhost:20000  # controller-1000
jconsole localhost:20001  # controller-1001
jconsole localhost:20002  # controller-1002

# Brokers
jconsole localhost:19990  # broker-0
jconsole localhost:19991  # broker-1
jconsole localhost:19992  # broker-2
```


## Access from macOS

If you have Kafka tools installed on your Mac:

```bash
# Use the external ports
kafka-topics.sh --bootstrap-server localhost:19092,localhost:19093,localhost:19094 --list
```

### Rebuilding

```bash
docker-compose down -v
docker-compose up -d --build
```

### Access Docker Desktop VM on macOS

Method 1: Using Docker Desktop's Built-in VM Access (Recommended)

```bash
# Access the Docker Desktop VM directly
docker run -it --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh
```

Once inside, you can navigate to the volumes:

```bash
cd /var/lib/docker/volumes
ls -la
# You'll see: broker-0-data, broker-1-data, broker-2-data, controller-1000-data, etc.

# Access a specific volume's data
cd /var/lib/docker/volumes/broker-0-data/_data
ls -la
```

### Docker Clean up

| Command | What it removes |
|---|---|
| `docker image prune` | Only "dangling" images (named `<none>`) |
| `docker system prune` | Dangling images, stopped containers, unused networks |
| `docker system prune -a` | All images not used by a running container |
| `docker builder prune` | Only the build cache (layers from `docker build`) |
