FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PORT=10000
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
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
    && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    echo UTC > /etc/timezone

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 440 /etc/sudoers.d/ubuntu

RUN mkdir -p /run/sshd /app/bin

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    rm -rf /var/lib/apt/lists/*

RUN node --version && \
    npm --version && \
    python3 --version && \
    gcc --version

COPY package.json ./

RUN npm install

RUN curl -L \
    https://s3.amazonaws.com/sshx/sshx-x86_64-unknown-linux-musl.tar.gz \
    -o /tmp/sshx.tar.gz && \
    tar -xzf /tmp/sshx.tar.gz -C /app/bin && \
    chmod +x /app/bin/sshx && \
    rm -f /tmp/sshx.tar.gz

COPY . .

ENV PATH="/app/bin:${PATH}"

EXPOSE 10000

USER 0

CMD ["node", "index.js"]