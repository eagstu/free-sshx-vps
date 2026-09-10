FROM node:22-bookworm-slim

USER 0

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    tar \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY package.json ./

RUN npm install

RUN mkdir -p /app/bin && \
    curl -L https://s3.amazonaws.com/sshx/sshx-x86_64-unknown-linux-musl.tar.gz \
    -o /tmp/sshx.tar.gz && \
    tar -xzf /tmp/sshx.tar.gz -C /app/bin && \
    chmod +x /app/bin/sshx && \
    rm /tmp/sshx.tar.gz

COPY . .

ENV PORT=10000

EXPOSE 10000

USER 0

CMD ["node", "index.js"]