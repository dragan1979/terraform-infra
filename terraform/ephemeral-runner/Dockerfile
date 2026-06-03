FROM ubuntu:22.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    zip \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install -y terraform

# Create a user for the GitHub Runner (running as root is not recommended/supported by GH)
RUN useradd -m github && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github

# Download the latest GitHub Actions Runner
RUN curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz \
    && tar xzf ./actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz

# Copy the startup script
COPY --chown=github:github start.sh .
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]