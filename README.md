# Infrastructure Hub: Multi-Environment Azure & DevOps Platform

This repository contains the Infrastructure as Code (IaC) and GitHub Actions CI/CD workflows for deploying a secure, scalable, and automated Azure environment. It manages the full lifecycle from core network provisioning to decoupled database deployments and GitOps-driven application delivery.

---

## Architecture Design

The platform is built on a modular, decoupled architecture designed for strict security, high availability, and isolated state management.

- **Decoupled State:** Infrastructure is split into Phase 1 (Core Infrastructure) and Phase 2 (Database/Data Plane) to minimize blast radius and prevent state lock collisions. Phase 2 dynamically reads outputs from Phase 1 via `terraform_remote_state`.
- **Networking:** A centralized VNET architecture (`vnet-hub`) with strictly isolated subnets for AKS, Bastion, Private Endpoints, PostgreSQL, and CI/CD Runners. The full address space is `10.0.0.0/22` (1,024 IPs), precisely carved into non-overlapping CIDR blocks per subnet.
- **Security:**
  - **Passwordless Authentication:** All pipelines utilize Azure OIDC for GitHub Actions.
  - **Workload Identity:** Replaces legacy Pod Identities. A User-Assigned Managed Identity (`id-petclinic-<env>`) establishes a direct "Bridge of Trust" between the `petclinic-sa` Kubernetes ServiceAccount and Azure Entra ID via a Federated Identity Credential.
  - **Secrets Management:** Azure Key Vault is configured with Private Link and strict RBAC-only access (`Key Vault Secrets User`). Database passwords are stored in Key Vault and fetched at runtime — never hardcoded.
- **Automation (Ephemeral Runners):** Static VMs have been replaced. Pipelines dynamically boot Azure Container Instances (ACI) inside the private network to execute Terraform runs, which self-destruct upon completion to ensure a pristine, zero-trust execution environment.

---

## Project Structure
```
├── .github/workflows/                   # CI/CD Pipeline Definitions
│   ├── terraform-core-plan-*.yaml       # Phase 1: Security scan & Plan for Core
│   ├── terraform-core-apply-*.yaml      # Phase 1: Automated deployment for Core
│   ├── terraform-db-plan-*.yaml         # Phase 2: Security scan & Plan for Database
│   └── terraform-db-apply-*.yaml        # Phase 2: Automated deployment for Database
│
├── ephemeral-runner/                    # Self-destructing CI/CD Runner Image
│   ├── Dockerfile                       # Builds the gh-tf-runner image (Ubuntu 22.04 + Azure CLI + Terraform + GH Runner)
│   └── start.sh                         # Entrypoint: registers runner via GitHub API, executes job, self-removes on completion
│
├── terraform/
│   ├── environments/                    # Environment-specific entry points
│   │   ├── dev/
│   │   │   ├── 01-core-infra/           # Phase 1: Core Infrastructure
│   │   │   │   ├── backend.tf           # AzureRM backend config (dev-core-infra.tfstate), provider & common tags
│   │   │   │   ├── main.tf              # Resource Groups, VNET/subnets, NAT Gateway, AKS, Key Vault, Jumpbox VM, PostgreSQL hardware, Workload Identity & Federated Credential
│   │   │   │   └── outputs.tf           # Exports: vnet_id, subnet IDs, petclinic_identity_client_id, key_vault_name, postgres_server_name, etc.
│   │   │   └── 02-database/             # Phase 2: Database Internals
│   │   │       ├── backend.tf           # AzureRM backend config (dev-data-plane.tfstate), azurerm + postgresql providers
│   │   │       └── main.tf              # Reads Phase 1 remote state; fetches Key Vault secrets; configures postgresql provider; deploys database-internals module
│   │   ├── staging/
│   │   │   ├── 01-core-infra/           # Phase 1 execution directory
│   │   │   │   ├── backend.tf
│   │   │   │   ├── main.tf
│   │   │   │   └── outputs.tf
│   │   │   └── 02-database/             # Phase 2 execution directory
│   │   │       ├── backend.tf
│   │   │       └── main.tf
│   │   └── prod/
│   │       ├── 01-core-infra/           # Phase 1 execution directory
│   │       │   ├── backend.tf
│   │       │   ├── main.tf
│   │       │   └── outputs.tf
│   │       └── 02-database/             # Phase 2 execution directory
│   │           ├── backend.tf
│   │           └── main.tf
│   └── modules/                         # Reusable Infrastructure Components
│       ├── vnet/                        # VNET & IP CIDR Subnetting
│       ├── nat-gateway/                 # Centralized Outbound Traffic Control
│       ├── aks/                         # Managed Kubernetes Cluster
│       ├── keyvault/                    # Secure Secret Management
│       ├── database-hardware/           # PostgreSQL Flexible Server Provisioning
│       ├── database-internals/          # PostgreSQL Roles & Schema Management
│       ├── vm/                          # Permanent Jumpboxes
│       └── bastion/                     # Secure PaaS Management Access
=======
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


---
```
## Environment Specifications

The infrastructure supports distinct configurations per environment to optimize for cost, performance, and strict state isolation.

| Feature | Dev Environment | Staging Environment | Prod Environment |
|---|---|---|---|
| **Region** | swedencentral | swedencentral | swedencentral |
| **AKS Nodes** | 2x Standard_B2s_v2 | 2x Standard_B2s_v2 | Highly Available |
| **Phase 1 State** | `dev-core-infra.tfstate` | `staging-core-infra.tfstate` | `prod-core-infra.tfstate` |
| **Phase 2 State** | `dev-data-plane.tfstate` | `staging-data-plane.tfstate` | `prod-data-plane.tfstate` |
| **Workload ID** | `id-petclinic-dev` | `id-petclinic-staging` | `id-petclinic-prod` |

---

## Key Infrastructure Components

### Ephemeral CI/CD Runners (`ephemeral-runner/`)

To guarantee a clean environment and eliminate permanent attack surfaces, all Terraform execution uses a custom-built, self-destructing runner image defined in the `ephemeral-runner/` directory.

**`Dockerfile`** — Builds the `gh-tf-runner` image on top of Ubuntu 22.04. It installs all required tooling in a single layer: `curl`, `jq`, `git`, Azure CLI, and Terraform (via HashiCorp's apt repository). A dedicated non-root `github` user is created for security compliance with GitHub Actions runner requirements. The GitHub Actions Runner binary (`v2.334.0`) is downloaded and extracted, and `start.sh` is copied in as the container entrypoint.

**`start.sh`** — The container entrypoint that drives the full runner lifecycle:
1. **Registration:** Calls the GitHub API with `GITHUB_TOKEN` to obtain a temporary registration token, then runs `config.sh` to register the runner with the target repository using the `--ephemeral` flag.
2. **Execution:** Calls `run.sh` to listen for and execute exactly one job.
3. **Self-Destruction:** After the job completes, obtains a removal token from the GitHub API and calls `config.sh remove` to fully deregister the runner, leaving no persistent resources behind.

### Phase 1 — Core Infrastructure (`01-core-infra/`)

The first deployment phase provisions all foundational Azure resources. It is driven by three files present in every environment directory.

**`backend.tf`** — Declares the `azurerm` provider constraint (`~> 3.0`), configures the remote state backend pointing to the environment-specific `.tfstate` key (e.g. `dev-core-infra.tfstate`), and defines `common_tags` applied to all resources.

**`main.tf`** — The primary resource manifest. It performs precise CIDR subnetting of the `10.0.0.0/22` address space using `cidrsubnet()` to carve out non-overlapping ranges for every subnet (AKS `/24`, Bastion `/26`, CI/CD `/29`, PostgreSQL `/28`, Private Endpoints `/28`, Jumpbox `/28`, Pipeline Agent `/29`). It then provisions:

- Five Resource Groups: `rg-core-network`, `aks-resource-group`, `rg-security-hub`, `vm-resource-group`, `postgres-resource-group`
- RBAC role assignments (`Role Based Access Control Administrator`, `Key Vault Secrets Officer`) scoped to the Key Vault RG
- Module calls: `vnet`, `nat_gateway`, `aks`, `keyvault`, `jumpbox_vm`, `postgres`
- Workload Identity chain: `azurerm_user_assigned_identity` → `azurerm_role_assignment` (`Key Vault Secrets User`) → `azurerm_federated_identity_credential` linking the AKS OIDC issuer to the `petclinic-sa` service account in the `dev` namespace

**`outputs.tf`** — Exports key values consumed by Phase 2 and post-deployment configuration: `vnet_id`, `vnet_name`, `cicd_subnet_id`, `bastion_subnet_id`, `aks_subnet_id`, `petclinic_identity_client_id` (for Kubernetes annotation), `azure_tenant_id`, `key_vault_name`, `keyvault_rg_name`, `postgres_server_name`, and `postgres_rg_name`.

### Phase 2 — Database Internals (`02-database/`)

The second deployment phase is intentionally decoupled from Phase 1, running against its own isolated state file and only executing after core infrastructure exists.

**`backend.tf`** — Declares both the `azurerm` (`~> 3.0`) and `postgresql` (`cyrilgdn/postgresql ~> 1.25.0`) provider requirements, configures the remote backend pointing to the environment-specific data-plane state key (e.g. `dev-data-plane.tfstate`), and defines `common_tags`.

**`main.tf`** — Reads Phase 1 outputs via `terraform_remote_state` (pointing at `dev-core-infra.tfstate`) to obtain the Key Vault name, Key Vault RG, PostgreSQL server name, and PostgreSQL RG — no hardcoded references across phases. It then fetches `postgres-admin-password` and `postgres-standard-user-password` from Key Vault at plan time to dynamically configure the `postgresql` provider (connecting to the server FQDN over SSL with `superuser = false`). Finally, it calls the `database-internals` module to apply roles and schema, passing the app user password retrieved from Key Vault.

### NAT Gateway (Outbound Security)

The `nat-gateway` module ensures all private resources have secure, controlled outbound access.

- **Fixed IP:** Uses a Static Standard Public IP for predictable external traffic identification.
- **Subnet Association:** Connected directly to the AKS Subnet (`vnet_aks_subnet_id`), the CI/CD Subnet (`vnet_cicd_subnet_id`), and the Pipeline Agent Subnet (`vnet_runner_subnet_id`) to allow package downloads and GitHub API registration.
- **Secure Access:** Ensures private resources can reach external APIs without being exposed to inbound internet threats.

### Workload Identity Integration

The architecture implements Azure Workload Identity to securely connect the AKS cluster to Azure Key Vault without storing credentials in Kubernetes.

- **Dedicated Identity:** A User-Assigned Managed Identity (`id-petclinic-<env>`) is provisioned explicitly for the application — one identity per application for least-privilege and clean auditing.
- **Strict RBAC:** The identity is granted `Key Vault Secrets User` scoped precisely to the Key Vault resource, allowing secret reads but no write or delete operations.
- **Federated Trust:** An OIDC federated credential (`fic-petclinic-<env>`) tells Azure Entra ID: *"Trust any token from the AKS OIDC issuer for the `petclinic-sa` service account in the target namespace."* The subject is set to `system:serviceaccount:<env>:petclinic-sa`.
=======
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

- **Trivy Scanning:** Every Pull Request triggers an automated Aquasecurity Trivy IaC Scanner check. It scans all Terraform files and modules for `CRITICAL` and `HIGH` vulnerabilities before any code is merged into `develop`, `staging`, or `prod`.
- **Azure Bastion:** Provides secure, browser-based TLS access to internal jumpbox virtual machines without requiring open RDP/SSH ports or public IP addresses.
- **Zero Hardcoded Secrets:** All sensitive values (PostgreSQL admin password, app user password) are generated and stored exclusively in Azure Key Vault. Phase 2 fetches them dynamically via `azurerm_key_vault_secret` data sources at plan time.
=======
### Workload Identity

Establishes a **"Bridge of Trust"** using Federated Identity Credentials. This allows pods to access Key Vault secrets (like database credentials) using Azure Entra ID tokens instead of static passwords.

### Trivy Scanning

Every Pull Request triggers an automated **Trivy IaC Scanner** check. It scans modules for `CRITICAL` and `HIGH` vulnerabilities before any code is merged.

### Azure Bastion

Provides secure, browser-based RDP/SSH access to internal virtual machines without requiring public IP addresses.
```
