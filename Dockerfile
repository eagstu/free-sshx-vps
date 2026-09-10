FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=10000

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    tar \
    procps \
    sudo \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 440 /etc/sudoers.d/ubuntu

USER 0

COPY package.json ./

RUN npm install

RUN mkdir -p /app/bin && \
    curl -L https://s3.amazonaws.com/sshx/sshx-x86_64-unknown-linux-musl.tar.gz \
    -o /tmp/sshx.tar.gz && \
    tar -xzf /tmp/sshx.tar.gz -C /app/bin && \
    chmod +x /app/bin/sshx && \
    rm /tmp/sshx.tar.gz

COPY . .

EXPOSE 10000

CMD ["node", "index.js"]