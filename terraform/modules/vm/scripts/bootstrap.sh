#!/bin/bash
# 1. Enforce Logging: Send all output of this script to a dedicated log file
exec > >(tee -a /var/log/vm-bootstrap.log) 2>&1
echo "Starting VM Bootstrap process..."

# 2. Update and install base dependencies
apt-get update -y
apt-get install -y ca-certificates curl gnupg jq apt-transport-https lsb-release

# 3. Install Docker
echo "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# 5. Install unzip
sudo apt-get update && sudo apt-get install unzip -y

# 6. Install kubectl and helm
sudo snap install kubectl --classic
sudo snap install helm --classic

# 7. Create the Runner User
# GitHub Actions runner CANNOT run as root. We must create a dedicated user and give it Docker access.
echo "Configuring GitHub Runner User..."
useradd -m -s /bin/bash gh-runner
usermod -aG docker gh-runner
usermod -aG sudo gh-runner
echo "gh-runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 8. Install OpenJDK 17 (Required for Spring Petclinic)
echo "📦 Installing Java 17..."
sudo apt-get install openjdk-17-jdk -y

# 9. Install Maven
echo "📦 Installing Maven..."
sudo apt-get install maven -y

# 10. Set JAVA_HOME environment variable (Critical for GitHub Actions Runners)
echo "⚙️ Configuring JAVA_HOME..."
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' | sudo tee -a /etc/profile.d/jdk.sh
echo 'export PATH=$PATH:$JAVA_HOME/bin' | sudo tee -a /etc/profile.d/jdk.sh
source /etc/profile.d/jdk.sh

# 11. Download and install yq
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq

# 12.Download the latest ArgoCD CLI binary
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# Install it to your local bin with execute permissions
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# Clean up the downloaded file
rm argocd-linux-amd64

# 13. Download the GitHub Actions Runner Binary
echo "Downloading GitHub Actions Runner..."
su - gh-runner -c "mkdir actions-runner && cd actions-runner && curl -o actions-runner-linux-x64-2.334.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz && tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz"

echo "Bootstrap completed successfully."
