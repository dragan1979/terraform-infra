###################### Management Security Group,rules and Associations #################

# The Security Group Container
resource "azurerm_network_security_group" "nsg_mgmt" {
  name                = "nsg-management"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Inbound Rule: Allow SSH ONLY from Public Jumpbox
resource "azurerm_network_security_rule" "allow_ssh_from_bastion" {
  name                        = "AllowSSHFromBastion"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes       = var.public_jumpbox_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg_mgmt.name
}

# 3. Outbound Rule: Allow HTTPS to Internet (for kubectl/helm updates)
resource "azurerm_network_security_rule" "allow_outbound_https" {
  name                        = "AllowHTTPSOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg_mgmt.name
}

# The Association (The "Glue")
resource "azurerm_subnet_network_security_group_association" "mgmt_assoc" {
  # Referencing the subnet name 'vm' from main.tf
  subnet_id                 = azurerm_subnet.cicd.id 
  network_security_group_id = azurerm_network_security_group.nsg_mgmt.id
}

###################### Bastion Security Group,rules and Associations #################

# The Security Group Container
resource "azurerm_network_security_group" "nsg_bastion" {
  name                = "nsg-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  # --- INBOUND RULES ---

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBastionHostCommunication"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # --- OUTBOUND RULES ---

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowBastionCommunication"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowGetSessionInformation"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}


resource "azurerm_subnet_network_security_group_association" "bastion_assoc" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.nsg_bastion.id
}


###################### AKS Security Group,rules and Associations #################


resource "azurerm_network_security_group" "nsg_aks" {
  name                = "nsg-aks"
  location            = var.location
  resource_group_name = var.resource_group_name

  # 1. Inbound: Allow all internal traffic within the AKS subnet
  # This is critical for Pod-to-Pod and Node-to-Node communication.
  security_rule {
    name                       = "AllowInternalAll"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.aks_subnet_prefixes
    destination_address_prefixes = var.aks_subnet_prefixes
  }

  # 2. Inbound: Allow traffic from the Management VM
  # This allows you to run kubectl commands from your Ubuntu box.
  security_rule {
    name                       = "AllowMgmtToAKS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443" # Kubernetes API Port
    source_address_prefixes    = var.pipeline_agent_subnet_prefixes
    destination_address_prefix = "*"
  }

  # 3. Inbound: Allow Azure Load Balancer
  # Required for health probes and exposing your Petclinic app later.
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 4. Inbound: Allow traffic from the Internet (for the Traefik Ingress Controller)
  security_rule {
    name                         = "AllowInternetInbound"
    priority                     = 130
    direction                    = "Inbound"
    source_address_prefix        = "Internet"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_ranges      = [ 80, 443 ]
    destination_address_prefixes = var.aks_subnet_prefixes
  }

  # 5. Outbound: Allow traffic to postgres Subnet
  # This opens the door for your app to reach the database.
  security_rule {
    name                       = "AllowAccessTopostgres"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefixes = var.postgres_subnet_prefixes
  }

  # 6. Outbound: Allow HTTPS to Internet
  # Required for pulling images and reaching the AKS Management API.
  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

# The Association (Gluing it to the AKS Subnet)
resource "azurerm_subnet_network_security_group_association" "aks_assoc" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.nsg_aks.id
}


###################### postgres Security Group,rules and Associations #################


resource "azurerm_network_security_group" "nsg_postgres" {
  name                = "nsg-postgres"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow Traffic from AKS
  security_rule {
    name                       = "AllowAKSTopostgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefixes    = var.aks_subnet_prefixes
    destination_address_prefix = "*"
  }

  # Allow Traffic from Management VM (For running DB migrations/troubleshooting)
  security_rule {
    name                       = "AllowMgmtTopostgres"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefixes    = var.cicd_subnet_prefixes
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowJumpboxTopostgres"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefixes    = var.public_jumpbox_cidr
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# The Association
resource "azurerm_subnet_network_security_group_association" "postgres_assoc" {
  subnet_id                 = azurerm_subnet.postgres.id
  network_security_group_id = azurerm_network_security_group.nsg_postgres.id
}

###################### Public Jumpbox Security Group,rules and Associations #################

# 2. The Public NSG
resource "azurerm_network_security_group" "public_jumpbox_nsg" {
  name                = "nsg-public-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow SSH ONLY from your home IP
  security_rule {
    name                       = "Allow-SSH-From-Home"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }
}

# 3. Associate NSG to the Subnet
resource "azurerm_subnet_network_security_group_association" "jumpbox_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public_jumpbox.id
  network_security_group_id = azurerm_network_security_group.public_jumpbox_nsg.id
}