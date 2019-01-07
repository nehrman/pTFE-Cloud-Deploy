######
# Azure Configuration 
######

provider "azurerm" {}

resource "azurerm_resource_group" "arm_rg" {
  name     = "test-neh"
  location = "francecentral"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

resource "azurerm_virtual_network" "arm_vnet" {
  name                = "test-vnet"
  location            = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name = "${azurerm_resource_group.arm_rg.name}"
  address_space       = ["10.0.0.0/16"]

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

resource "azurerm_subnet" "arm_subnet" {
  name                 = "test-subnet"
  virtual_network_name = "${azurerm_virtual_network.arm_vnet.name}"
  resource_group_name  = "${azurerm_resource_group.arm_rg.name}"
  address_prefix       = "10.0.1.0/24"
  count                = "${var.cloud_provider == "arm" ? 1 : 0}"
}

resource "azurerm_storage_account" "arm_storageaccount" {
  name                     = "testnehstoacct"
  resource_group_name      = "${azurerm_resource_group.arm_rg.name}"
  location                 = "${azurerm_resource_group.arm_rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

# Create Network Nic to use with VM
resource "azurerm_network_interface" "arm_nics" {
  count                     = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"
  name                      = "nic-${count.index}"
  location                  = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name       = "${azurerm_resource_group.arm_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.arm_nsg.id}"

  ip_configuration {
    name                          = "ipconf1"
    subnet_id                     = "${azurerm_subnet.arm_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }
}

# Create Security Group related to VMs
resource "azurerm_network_security_group" "arm_nsg" {
  name                = "test-sg"
  location            = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name = "${azurerm_resource_group.arm_rg.name}"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

resource "azurerm_network_security_rule" "arm_custom_rules" {
  count                       = "${length(var.custom_security_rules)}"
  resource_group_name         = "${azurerm_resource_group.arm_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.arm_nsg.name}"
  name                        = "${lookup(var.custom_security_rules[count.index], "name")}"
  priority                    = "${lookup(var.custom_security_rules[count.index], "priority")}"
  direction                   = "${lookup(var.custom_security_rules[count.index], "direction")}"
  access                      = "${lookup(var.custom_security_rules[count.index], "access")}"
  protocol                    = "${lookup(var.custom_security_rules[count.index], "protocol")}"
  source_port_range           = "${lookup(var.custom_security_rules[count.index], "source_port_range")}"
  destination_port_range      = "${lookup(var.custom_security_rules[count.index], "destination_port_range")}"
  source_address_prefix       = "${lookup(var.custom_security_rules[count.index], "source_address_prefix")}"
  destination_address_prefix  = "${lookup(var.custom_security_rules[count.index], "destination_address_prefix")}"
}

# Create Azure Instances
resource "azurerm_virtual_machine" "arm_vm" {
  count                 = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"
  name                  = "vm-${count.index}"
  location              = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name   = "${azurerm_resource_group.arm_rg.name}"
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
    name              = "vm-${count.index}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm-${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


######
# AWS Configuration 
######

provider "aws" {}

