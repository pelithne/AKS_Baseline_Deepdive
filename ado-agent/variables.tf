variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "rg-agent-terraform"
}

variable "location" {
  description = "The location of the resources"
  default     = "swedencentral"
}

variable "vnet_address_space" {
  description = "The address space of the virtual network"
  default     = "10.2.0.0/24"
}

variable "subnet_address_prefixes" {
  description = "The address prefixes of the subnet"
  default     = "10.2.0.0/24"
}

variable "admin_password" {
  description = "The admin password of the virtual machine"
  type        = string

}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  default     = "agent-vnet"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "agent-subnet"
  type        = string
}

variable "azp_pool" {
  description = "The pool of the Azure DevOps organization"
  default     = "default"
  type        = string
}

variable "vm_extension_name" {
  description = "The name of the extension"
  default     = "ADO-agent-extension"
  type        = string
}

variable "computer_name" {
  description = "The name of the virtual machine"
  default     = "ado-agent"
  type        = string
}


variable "org_service_url" {
  description = "The Azure DevOps organization URL"
}

variable "personal_access_token" {
  description = "The personal access token for Azure DevOps"
}