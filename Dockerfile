
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PORT=10000
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DOCKER_HOST=unix:///var/run/docker.sock

WORKDIR /app

RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    bash \
    bash-completion \
    coreutils \
    procps \
    psmisc \
    util-linux \
    file \
    findutils \
    grep \
    sed \
    gawk \
    nano \
    vim \
    less \
    man-db \
    manpages \
    manpages-dev \
    git \
    openssh-client \
    openssh-server \
    rsync \
    ftp \
    telnet \
    dnsutils \
    iputils-ping \
    iproute2 \
    net-tools \
    traceroute \
    netcat-openbsd \
    socat \
    lsof \
    htop \
    tree \
    jq \
    unzip \
    zip \
    bzip2 \
    gzip \
    xz-utils \
    tar \
    zstd \
    p7zip-full \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    perl \
    ruby \
    openssl \
    libssl-dev \
    zlib1g-dev \
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    sqlite3 \
    tmux \
    screen \
    cron \
    tzdata \
    locales \
    iptables \
    docker.io \
    docker-compose-v2 \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo UTC > /etc/timezone

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 440 /etc/sudoers.d/ubuntu

RUN mkdir -p /run/sshd /app/bin /var/lib/docker

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

RUN node --version \
    && npm --version \
    && python3 --version \
    && gcc --version \
    && docker --version \
    && docker compose version

COPY package.json ./

RUN npm install

ARG TARGETARCH

RUN case "${TARGETARCH}" in \
      amd64) SSHX_ARCH="x86_64" ;; \
      arm64) SSHX_ARCH="aarch64" ;; \
      *) echo "Arquitetura não suportada pelo SSHX: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && curl -fsSL \
    "https://s3.amazonaws.com/sshx/sshx-${SSHX_ARCH}-unknown-linux-musl.tar.gz" \
    -o /tmp/sshx.tar.gz \
    && tar -xzf /tmp/sshx.tar.gz -C /app/bin \
    && chmod +x /app/bin/sshx \
    && rm -f /tmp/sshx.tar.gz


COPY . .

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

ENV PATH="/app/bin:${PATH}"

EXPOSE 10000

USER root

ENTRYPOINT ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
