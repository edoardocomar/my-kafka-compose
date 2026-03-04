# Use Eclipse Temurin Java 21 Alpine as base image
FROM eclipse-temurin:21-jre-alpine

# Install required utilities
RUN apk add --no-cache \
    bash \
    curl \
    netcat-openbsd

# Set up Kafka directory
WORKDIR /opt

# Copy the Kafka tarball from the build context
COPY kafka_2.13-4.2.0.tgz /tmp/kafka.tgz

# Extract Kafka
RUN tar -xzf /tmp/kafka.tgz -C /opt && \
    mv /opt/kafka_2.13-4.2.0 /opt/kafka && \
    rm /tmp/kafka.tgz

# Set Kafka home
ENV KAFKA_HOME=/opt/kafka
ENV PATH=$PATH:$KAFKA_HOME/bin

# Create directories for logs and data
RUN mkdir -p /var/lib/kafka/data /var/log/kafka

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /opt/kafka

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]