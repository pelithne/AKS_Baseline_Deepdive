variable "virtual_network_name" {
  description = "The name of the virtual network"
  default     = "agent-vnet"
  type        = string
}
variable "location" {
  description = "The location/region of the resource"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "vnet_address_space" {
  description = "The address prefixes that is used the subnet"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "The address prefixes that is used the subnet"
  type        = list(string)
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "agent-subnet"
  type        = string
}

