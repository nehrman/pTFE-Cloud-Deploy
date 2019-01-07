# Variable uses to define which cloud provider should be use to deploy pTFE
variable "cloud_provider" {
  default = "aws"
}

# Variable uses to define the count of Instances to deploy
variable "vm_count" {
  default = "2"
}

# Global variables used to define configuration of security rules whatever the cloud provider is

variable "custom_security_rules" {
  description = "Create all security rules needed by default"
  type        = "list"

  default = [
    {
      name                       = "HTTP"
      priority                   = "1000"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "HTTPS"
      priority                   = "1001"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
        {
      name                       = "SSH"
      priority                   = "1002"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
            {
      name                       = "REPLICATED"
      priority                   = "1003"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "tcp"
      source_port_range          = "*"
      destination_port_range     = "8800"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}
