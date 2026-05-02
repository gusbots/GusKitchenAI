FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    sudo \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspaces/GusKitchenAI

COPY requirements.txt .
RUN pip3 install --break-system-packages -r requirements.txt

RUN git config --system --add safe.directory /workspaces/GusKitchenAI && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ubuntu
