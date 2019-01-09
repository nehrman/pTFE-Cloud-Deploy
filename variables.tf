# Variable used to define which cloud provider should be use to deploy pTFE
variable "cloud_provider" {
  default = "arm"
}

# Variable used to define which region in regards to which cloud provider

variable "cloud_region" {
  type = "map"

  default = {
    arm = "francecentral"
    aws = "eu-central-1"
    gcp = "eu-west1"
  }
}

# Variable used to define which dns zone in regards to which cloud provider

variable "cloud_dns_zone" {
  type = "map"

  default = {
    arm = "demoaz"
    aws = "demoaws"
    gcp = "demogcp"
  }
}

# Variable uses to define the count of Instances to deploy
variable "vm_count" {
  default = "3"
}

# Global variable for SSH key name

variable "global_key_name" {
  default = "vault-test"
}

# Global Address space Variable

variable "global_address_space" {
  description = "Define the global address space used by Cloud Network"
  default     = "10.0.0.0/16"
}

# Global CIDR Blocks list used for Security Rules configuration

variable "ec2_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

# Global variables used to define configuration of security rules whatever the cloud provider is

variable "arm_custom_security_rules" {
  description = "Create all security rules needed by default for Azure"
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

variable "ec2_custom_security_rules" {
  description = "Create all security rules needed by default for Azure"
  type        = "list"

  default = [
    {
      type        = "ingress"
      from_port   = "22"
      to_port     = "22"
      protocol    = "tcp"
      description = "SSH access TFE"
    },
    {
      type        = "ingress"
      from_port   = "80"
      to_port     = "80"
      protocol    = "tcp"
      description = "HTTP access TFE"
    },
    {
      type        = "ingress"
      from_port   = "443"
      to_port     = "443"
      protocol    = "tcp"
      description = "HTTPS access TFE"
    },
    {
      type        = "ingress"
      from_port   = "8800"
      to_port     = "8800"
      protocol    = "tcp"
      description = "Access TFE"
    },
    {
      type        = "egress"
      from_port   = "0"
      to_port     = "65535"
      protocol    = "-1"
      description = "Allow all"
    },
  ]
}
