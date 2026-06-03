variable "vm_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "The ID of the snet-mgmt subnet"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_ssh_public_key" {
  type        = string
  description = "The public SSH key string to inject into the VM"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFrQaW2ZYIpsvowd7nxOauHKR0RHMdeqZvfytv7mQ+xoAmlxPhAeGTtH7+nSCGavwaeRFBLGuhcZnQL9Zi0uff6Uvnuw7hJ7uEJnU38PvzqOidpaNHFpWzuL+CJg+tmKcqbe8Vi7p528uFZyjEkvkqDzfdQUtAMoDA20uQabJIL1P/QMhVa/t2+F/87uspWd0GbZxCaLuXDxTdSmDCUnH4lAseB2Kjt+cqnaoqYgw2k4239vatkUOH+ju/nneoGZ6Ub6wuq4COQoEgE3u1lovBlMRxkvxvOsz3W+uRpLXGvMnHxfhtPsobDhV1buw4+nhkDfDEMkZVKbLwnu0niwy31dqYQZojG6H1DV74iTHVG6NaPW2t0gFtvm7aUIDmxvIRrXVIqc3Kk5p67cjU0eYupP22Co6pu+EMo2L7dSU16PyOFm39JlYxfFxcOGxfPU40Z0ZUV5qzsWW09MgqAh1Tr/mIuvI8/cCliWMWGFf0guJPUgUGdvmLbxE0BRTIPIX1AVdGFS5Jrz4Uvs3HbSOVuqUWiFctsKFstnwwSZKsYTOJkcu/TjGBPMXpCqtGCZbcHPBKTU2tSmeGCBuLZnE5hwmgCeg4XtbOojLsW9L7W5THf3CzrGSl9YLWR/1vqeQXEDeI5wPuzB+W3XyqDfJ0VsPkLP/OeonIZQA5d+Q41Q== mera\\dravucan@RSM005766"
}

variable "aks_id" {
  type        = string
  default     = ""
  description = "The ID of the AKS cluster"
}

variable "create_public_ip" {
  type        = bool
  description = "Set to true to assign a Public IP to the VM"
  default     = false
}

variable "is_cicd_agent" {
  type        = bool
  description = "Set to true if this VM needs AKS Identity, Role Assignments, and a bootstrap script"
  default     = false
}

variable vm_size {
  description = "The size of the Virtual Machines."
  type        = string
  default     = "Standard_B2s_v2"
}