# Infrastructure Hub: Multi-Environment Azure & DevOps Platform

This repository contains the **Infrastructure as Code (IaC)** and **GitHub Actions CI/CD workflows** for deploying a secure, scalable, and automated Azure environment. It manages the full lifecycle from network provisioning to GitOps-driven application delivery.

---

##  Architecture Design

The platform is built on a modular hub-and-spoke networking model designed for security and high availability.

- **Networking**: A centralized VNET architecture (`vnet-hub`) with isolated subnets for AKS, Bastion, Private Endpoints, PostgreSQL, and CI/CD Runners.
- **Security**:
  - **Passwordless Authentication**: All pipelines utilize Azure OIDC for GitHub Actions.
  - **Identity Management**: System-Assigned Managed Identities are used for secure VM-to-AKS communication.
  - **Secrets Management**: Azure Key Vault is configured with Private Link and strict RBAC-only access via "Key Vault Secrets User" roles.
- **Automation**: Self-hosted GitHub Runners are automatically bootstrapped with the full DevOps toolchain via cloud-init scripts.

---

##  Project Structure

```text
├── .github/workflows/           # CI/CD Pipeline Definitions
│   ├── terraform-plan-dev.yaml  # Security scan & Plan for Dev
│   ├── terraform-apply-dev.yaml # Automated deployment to Dev
│   ├── terraform-plan-prod.yaml # Security scan & Plan for Prod
│   ├── terraform-apply-prod.yaml# Automated deployment to Prod
│   
├── terraform/
│   ├── environments/            # Environment-specific entry points
│   │   ├── dev/                 # Development (swedencentral)
│   │   ├── staging/             # Staging (North Europe)
│   │   └── prod/                # Production environment
│   └── modules/                 # Reusable Infrastructure Components
│       ├── vnet/                # VNET & Subnets
│       ├── nat-gateway/         # Centralized Outbound Traffic Control
│       ├── aks/                 # Managed Kubernetes Cluster
│       ├── keyvault/            # Secure Secret Management
│       ├── database/            # PostgreSQL Flexible Server
│       ├── vm/                  # CI/CD Runners & Jumpboxes
        |    | -- scripts/runner-bootstrap.yaml    # K8s addons (ArgoCD, Traefik, etc.)     
│       └── bastion/             # Secure PaaS Management Access
```

---

## Environment Specifications

The infrastructure supports distinct configurations per environment to optimize for cost and performance.

| Feature        | Dev Environment         | Staging Environment       |
|----------------|-------------------------|---------------------------|
| **Region**     | swedencentral           | North Europe              |
| **AKS Nodes**  | 2x Standard_B2s_v2      | 1x Standard_B2s_v2        |
| **VNET Space** | 10.0.0.0/22             | 10.0.0.0/22               |
| **State File** | dev.terraform.tfstate   | staging.terraform.tfstate |
| **Workload ID**| id-petclinic-dev        | id-petclinic-staging      |

---

## Key Infrastructure Modules

### NAT Gateway (Outbound Security)

The `nat-gateway` module ensures all private resources have secure, controlled outbound access:

- **Fixed IP**: Uses a Static Standard Public IP for predictable external traffic identification.
- **Subnet Association**: Connected directly to the AKS Subnet and CI/CD VM Subnet.
- **Secure Access**: Allows private resources to reach external APIs or download updates without being exposed to inbound internet threats.

### CI/CD Runner Bootstrapping

Self-hosted runners are automatically provisioned and configured using a `bootstrap.sh` script:

- **Containerization**: Installs Docker CE and Containerd for building container images.
- **Development Stack**: Pre-configures OpenJDK 17 and Maven for Spring Boot application builds.
- **Management Tools**: Installs `kubectl`, `helm`, and Azure CLI to manage cloud resources.
- **Runner Lifecycle**: Downloads and sets up the GitHub Actions runner binary under a dedicated `gh-runner` user.

### Kubernetes GitOps & Bootstrapping

After the cluster is provisioned, the `runner-bootstrap` workflow installs core services via Helm:

- **ArgoCD**: Used for automated, GitOps-based application delivery.
- **Traefik**: Deployed as the cluster Ingress Controller for traffic routing.
- **External Secrets Operator**: Synchronizes Azure Key Vault secrets into Kubernetes natively.
- **Cert-Manager**: Automates the issuance and renewal of SSL/TLS certificates.

---

## Security Protocols

### Workload Identity

Establishes a **"Bridge of Trust"** using Federated Identity Credentials. This allows pods to access Key Vault secrets (like database credentials) using Azure Entra ID tokens instead of static passwords.

### Trivy Scanning

Every Pull Request triggers an automated **Trivy IaC Scanner** check. It scans modules for `CRITICAL` and `HIGH` vulnerabilities before any code is merged.

### Azure Bastion

Provides secure, browser-based RDP/SSH access to internal virtual machines without requiring public IP addresses.
