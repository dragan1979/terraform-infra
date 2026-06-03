resource "azurerm_public_ip" "pip" {
  count               = var.create_public_ip ? 1 : 0
  name                = "pip-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}




# Create a Network Interface (NIC) with NO Public IP
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    
    # If create_public_ip is true, attach it. Otherwise, set to null.
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.pip[0].id : null
  }
}

# The Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size # Verified budget-friendly option
  admin_username      = "azureuser"
  zone                = "1"
  
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS" # Standard SSD saves money over Premium
  }

  # Use the latest Ubuntu 22.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  # VM needs to be assigned a System Assigned Managed Identity in order it can securely pull the AKS credentials 
  # without needing passwords.It turns the Virtual Machine itself into an authenticated Azure entity, completely eliminating the need to generate, store, or rotate passwords.
# Conditionally create the Managed Identity block
  dynamic "identity" {
    for_each = var.is_cicd_agent ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Conditionally attach the bootstrap script
  custom_data = var.is_cicd_agent ? base64encode(templatefile("${path.module}/scripts/bootstrap.sh", {})) : null
  tags = var.tags
}

# Grants VM the "Azure Kubernetes Service Cluster User Role".This role allows the VM to download the kubeconfig file.
# Conditionally grant the AKS Role Assignment

resource "azurerm_role_assignment" "jumpbox_aks_access" {
  # Point this to the ID of AKS cluster resource
  count                = var.is_cicd_agent ? 1 : 0
  scope                = var.aks_id
  
  # The specific built-in Azure role for pulling AKS credentials
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  
  # Point this to the newly created Identity of the VM
  # We use try() because if is_cicd_agent is false, the identity block doesn't exist to reference
  principal_id         = try(azurerm_linux_virtual_machine.vm.identity[0].principal_id, "")
}
