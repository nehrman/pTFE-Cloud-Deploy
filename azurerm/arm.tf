#######################
# Azure Configuration #
#######################

provider "azurerm" {}

# Create Resource Group

resource "azurerm_resource_group" "arm_rg" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name     = "rg-${var.global_environment}-${var.global_purpose}"
  location = "${lookup(var.cloud_region, var.cloud_provider,)}"

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create Virtual Network

resource "azurerm_virtual_network" "arm_vnet" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name                = "vnet-${var.global_environment}-${var.global_purpose}"
  location            = "${azurerm_resource_group.arm_rg[count.index].location}"
  resource_group_name = "${azurerm_resource_group.arm_rg[count.index].name}"
  address_space       = ["${var.global_address_space}"]

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create Subnets attached to Virtual Network

resource "azurerm_subnet" "arm_subnet" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name                 = "subnet-${var.global_environment}-${var.global_purpose}"
  virtual_network_name = "${azurerm_virtual_network.arm_vnet[count.index].name}"
  resource_group_name  = "${azurerm_resource_group.arm_rg[count.index].name}"
  address_prefix       = "${cidrsubnet(var.global_address_space, 8, 1)}"
}

# Create Storage Account

resource "azurerm_storage_account" "arm_storageaccount" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name                     = "stoaccnt${lower(var.global_environment)}${lower(var.global_purpose)}"
  resource_group_name      = "${azurerm_resource_group.arm_rg[count.index].name}"
  location                 = "${azurerm_resource_group.arm_rg[count.index].location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create DNS Zone 

resource "azurerm_dns_zone" "arm_dns_zone" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name                = "demo${var.cloud_provider}.my-v-world.com"
  resource_group_name = "${azurerm_resource_group.arm_rg[count.index].name}"
  zone_type           = "Public"
}

# Create Public IPs that will be attached to VMs

resource "azurerm_public_ip" "arm_vm_pub_ip" {
  count = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"

  name                         = "pubip-${var.global_vm_apps}-${var.global_environment}-${var.global_purpose}-${count.index}"
  location                     = "${azurerm_resource_group.arm_rg[count.index].location}"
  resource_group_name          = "${azurerm_resource_group.arm_rg[count.index].name}"
  public_ip_address_allocation = "static"

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create Network Nics to use with VM
resource "azurerm_network_interface" "arm_nics" {
  count = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"

  name                      = "nic-${var.global_vm_apps}-${var.global_environment}-${var.global_purpose}-${count.index}"
  location                  = "${azurerm_resource_group.arm_rg[count.index].location}"
  resource_group_name       = "${azurerm_resource_group.arm_rg[count.index].name}"
  network_security_group_id = "${azurerm_network_security_group.arm_nsg[count.index].id}"

  ip_configuration {
    name                          = "ipconf1"
    subnet_id                     = "${azurerm_subnet.arm_subnet[count.index].id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create Security Group related to VMs
resource "azurerm_network_security_group" "arm_nsg" {
  count = "${var.cloud_provider == "arm" ? 1 : 0}"

  name                = "sg-${var.global_environment}-${var.global_purpose}"
  location            = "${azurerm_resource_group.arm_rg[count.index].location}"
  resource_group_name = "${azurerm_resource_group.arm_rg[count.index].name}"

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }
}

# Create Custom Rules for Security Group

resource "azurerm_network_security_rule" "arm_custom_rules" {
  count = "${length(var.arm_custom_security_rules) * (var.cloud_provider == "arm" ? 1 : 0)}"

  resource_group_name         = "${azurerm_resource_group.arm_rg[count.index].name}"
  network_security_group_name = "${azurerm_network_security_group.arm_nsg[count.index].name}"
  name                        = "${lookup(var.arm_custom_security_rules[count.index], "name")}"
  priority                    = "${lookup(var.arm_custom_security_rules[count.index], "priority")}"
  direction                   = "${lookup(var.arm_custom_security_rules[count.index], "direction")}"
  access                      = "${lookup(var.arm_custom_security_rules[count.index], "access")}"
  protocol                    = "${lookup(var.arm_custom_security_rules[count.index], "protocol")}"
  source_port_range           = "${lookup(var.arm_custom_security_rules[count.index], "source_port_range")}"
  destination_port_range      = "${lookup(var.arm_custom_security_rules[count.index], "destination_port_range")}"
  source_address_prefix       = "${lookup(var.arm_custom_security_rules[count.index], "source_address_prefix")}"
  destination_address_prefix  = "${lookup(var.arm_custom_security_rules[count.index], "destination_address_prefix")}"
}

# Create Azure VMs

resource "azurerm_virtual_machine" "arm_vm" {
  count = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"

  name                  = "${var.global_vm_apps}-${var.global_environment}-${var.global_purpose}-${count.index}"
  location              = "${azurerm_resource_group.arm_rg[count.index].location}"
  resource_group_name   = "${azurerm_resource_group.arm_rg[count.index].name}"
  network_interface_ids = ["${element(azurerm_network_interface.arm_nics.*.id, count.index)}"]
  vm_size               = "Standard_DS1_V2"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.global_vm_apps}-${var.global_environment}-${var.global_purpose}-${count.index}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.global_vm_apps}-${var.global_environment}-${var.global_purpose}-${count.index}"
    admin_username = "${var.global_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.global_admin_username}/.ssh/authorized_keys"
      key_data = "${element(var.ssh_public_key, 0)}"
    }
  }

  tags = {
    environment = "${var.global_environment}"
    owner       = "${var.global_owner}"
    purpose     = "${var.global_purpose}"
    cloud       = "${var.cloud_provider}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS Record for each VMs

resource "azurerm_dns_a_record" "arm_vm_record" {
  count = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"

  name                = "${element(azurerm_virtual_machine.arm_vm.*.name, count.index)}"
  zone_name           = "${azurerm_dns_zone.arm_dns_zone[count.index].name}"
  resource_group_name = "${azurerm_resource_group.arm_rg[count.index].name}"
  ttl                 = "300"
  records             = ["${element(azurerm_public_ip.arm_vm_pub_ip.*.ip_address, count.index)}"]
}
