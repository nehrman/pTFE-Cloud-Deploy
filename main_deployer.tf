#######################
# Azure Configuration #
#######################

provider "azurerm" {}

# Create Resource Group

resource "azurerm_resource_group" "arm_rg" {
  name     = "test-neh"
  location = "${lookup(var.cloud_region, var.cloud_provider,)}"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

# Create Virtual Network

resource "azurerm_virtual_network" "arm_vnet" {
  name                = "test-vnet"
  location            = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name = "${azurerm_resource_group.arm_rg.name}"
  address_space       = ["${var.global_address_space}"]

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

# Create Subnets attached to Virtual Network

resource "azurerm_subnet" "arm_subnet" {
  name                 = "test-subnet"
  virtual_network_name = "${azurerm_virtual_network.arm_vnet.name}"
  resource_group_name  = "${azurerm_resource_group.arm_rg.name}"
  address_prefix       = "${cidrsubnet(var.global_address_space, 8, 1)}"
  count                = "${var.cloud_provider == "arm" ? 1 : 0}"
}

# Create Storage Account

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

resource "azurerm_dns_zone" "arm_dns_zone" {
  name                = "demo${var.cloud_provider}.my-v-world.com"
  resource_group_name = "${azurerm_resource_group.arm_rg.name}"
  zone_type           = "Public"

  count = "${var.cloud_provider == "arm" ? 1 : 0}"
}

resource "azurerm_public_ip" "arm_vm_pub_ip" {
  name                         = "testpubip-${count.index}"
  location                     = "${azurerm_resource_group.arm_rg.location}"
  resource_group_name          = "${azurerm_resource_group.arm_rg.name}"
  public_ip_address_allocation = "static"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.vm_count * (var.cloud_provider == "arm" ? 1 : 0)}"
}

# Create Network Nics to use with VM
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

# Create Custom Rules for Security Group

resource "azurerm_network_security_rule" "arm_custom_rules" {
  count                       = "${length(var.arm_custom_security_rules) * (var.cloud_provider == "arm" ? 1 : 0)}"
  resource_group_name         = "${azurerm_resource_group.arm_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.arm_nsg.name}"
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

resource "azurerm_dns_a_record" "arm_vm_record" {
  name                = "${element(azurerm_virtual_machine.arm_vm.*.name, count.index)}"
  zone_name           = "${azurerm_dns_zone.arm_dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.arm_rg.name}"
  ttl                 = "300"
  records             = ["${element(azurerm_public_ip.arm_vm_pub_ip.*.ip_address, count.index)}"]
}

#####################
# AWS Configuration #
#####################

provider "aws" {
  region = "${lookup(var.cloud_region, "aws")}"
}

resource "aws_vpc" "ec2_vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_subnet" "ec2_subnet" {
  vpc_id                  = "${aws_vpc.ec2_vpc.id}"
  cidr_block              = "${cidrsubnet(var.global_address_space, 8, 1)}"
  map_public_ip_on_launch = true

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_internet_gateway" "ec2_igw" {
  vpc_id = "${aws_vpc.ec2_vpc.id}"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_route_table" "ec2_rtb" {
  vpc_id = "${aws_vpc.ec2_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ec2_igw.id}"
  }

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_route_table_association" "ec2_rtb_assoc" {
  subnet_id      = "${aws_subnet.ec2_subnet.id}"
  route_table_id = "${aws_route_table.ec2_rtb.id}"

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_security_group" "ec2_sg" {
  name        = "pTFE_sg"
  description = "Security Group allowing access to pTFE instance"
  vpc_id      = "${aws_vpc.ec2_vpc.id}"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }

  count = "${var.cloud_provider == "aws" ? 1 : 0}"
}

resource "aws_security_group_rule" "ec2_custom_rules" {
  count             = "${length(var.ec2_custom_security_rules) * (var.cloud_provider == "aws" ? 1 : 0)}"
  type              = "${lookup(var.ec2_custom_security_rules[count.index], "type")}"
  from_port         = "${lookup(var.ec2_custom_security_rules[count.index], "from_port")}"
  to_port           = "${lookup(var.ec2_custom_security_rules[count.index], "to_port")}"
  protocol          = "${lookup(var.ec2_custom_security_rules[count.index], "protocol")}"
  cidr_blocks       = "${var.ec2_cidr_blocks}"
  description       = "${lookup(var.ec2_custom_security_rules[count.index], "description")}"
  security_group_id = "${aws_security_group.ec2_sg.id}"
}

resource "aws_instance" "ec2_vm" {
  count                       = "${var.vm_count * (var.cloud_provider == "aws" ? 1 : 0)}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.large"
  subnet_id                   = "${aws_subnet.ec2_subnet.id}"
  private_ip                  = "${cidrhost(aws_subnet.ec2_subnet.cidr_block, count.index + 100)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.ec2_sg.id}"]
  key_name                    = "${var.global_key_name}"

  tags {
    environnement = "test"
    owner         = "neh"
    purpose       = "Testing"
    cloud         = "${var.cloud_provider}"
  }
}

#####################
# GCP Configuration #
#####################

provider "google" {}

resource "google_compute_network" "gcp_net" {
  name                    = "test"
  auto_create_subnetworks = false
  count                   = "${var.cloud_provider == "gcp" ? 1 : 0}"
}

resource "google_compute_subnetwork" "gcp_subnets" {
  name          = "testsubnet"
  ip_cidr_range = "${var.global_address_space}"
  region        = "${lookup(var.cloud_region, var.cloud_provider,)}"
  network       = "${google_compute_network.gcp_net.self_link}"

  count = "${1 * (var.cloud_provider == "gcp" ? 1 : 0)}"
}

resource "google_compute_address" "gcp_int_addr" {
  name         = "test-int"
  subnetwork   = "${element(google_compute_subnetwork.gcp_subnets.*.self_link, count.index)}"
  address_type = "INTERNAL"

  count = "${var.cloud_provider == "gcp" ? 1 : 0}"
}

resource "google_compute_address" "gcp_ext_addr" {
  name = "test-ext"

  count = "${var.cloud_provider == "gcp" ? 1 : 0}"
}

// resource "google_compute_firewall" "gcp_custom_rules" {}

resource "google_compute_instance" "gcp_vm" {
  name                      = "test-vm"
  machine_type              = "n1-standard-4"
  zone                      = "europe-west1-b"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    network    = "${google_compute_network.gcp_net.self_link}"
    network_ip = "${google_compute_address.gcp_int_addr.address}"

    access_config {
      nat_ip = "${google_compute_address.gcp_ext_addr.address}"
    }
  }

  count = "${var.vm_count * (var.cloud_provider == "gcp" ? 1 : 0)}"
}
