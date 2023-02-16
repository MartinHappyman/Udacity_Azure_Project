provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "project" {
  name     = "${var.prefix}-RG"
  location = var.location

    tags = {
    Project = "${var.Project}"
  }
}

resource "azurerm_virtual_network" "project" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

    tags = {
    Project = "${var.Project}"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.project.name
  virtual_network_name = azurerm_virtual_network.project.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_public_ip" "project" {
 # count = var.vm_count
 # name                = "${var.prefix}-PublicIP_${count.index}"
  name                = "${var.prefix}-PublicIP"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location
  allocation_method   = "Dynamic"

    tags = {
    Project = "${var.Project}"
  }
}

resource "azurerm_network_interface" "project" {
 # count               = var.vm_count
 # name                = "${var.prefix}-nic_${count.index}"
   name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.project.name
  location            = azurerm_resource_group.project.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.project.id
  }
  tags = {
  Project = "${var.Project}"
  }
}

resource "azurerm_network_security_group" "project" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
  Project = "${var.Project}"
  }
}

data "azurerm_resource_group" "image" {
  name                = var.packer_resource_group_name
}

data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.image.name
}

resource "azurerm_virtual_machine" "project" {
 # count                  = var.vm_count
 # name                   = "UbuntuVM_${count.index}"
   name                   = "${var.prefix}_UbuntuVM"
  location               = azurerm_resource_group.project.location
  resource_group_name    = azurerm_resource_group.project.name
  network_interface_ids  = ["${azurerm_network_interface.project.id}"]
  vm_size                = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "${var.prefix}_osd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
}

  os_profile {
    computer_name = "UbuntuVM"
    admin_username = "maradm"
    admin_password = "M@rcin2022"
  }
  os_profile_linux_config {
    disable_password_authentication = false
}

  tags = {
  Project = "${var.Project}"
  }
}

resource "azurerm_lb" "project" {
 # count = var.vm_count
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name

frontend_ip_configuration {
    name                          = "${var.prefix}-feip"
    public_ip_address_id          = azurerm_public_ip.project.id
}
}

resource "azurerm_lb_backend_address_pool" "project" {
  name                = "${var.prefix}-bap"
  loadbalancer_id     = azurerm_lb.project.id
}

resource "azurerm_lb_probe" "project" {
    name                      = "${var.prefix}-probe"
    protocol                  = "Tcp"
    port                      = 80
    loadbalancer_id           = azurerm_lb.project.id
}

resource "azurerm_lb_rule" "project" {
    name                           = "${var.prefix}-lbr"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = azurerm_lb.project.frontend_ip_configuration[0].name
    probe_id                       = azurerm_lb_probe.project.id
    loadbalancer_id                = azurerm_lb.project.id
}


resource "azurerm_network_interface_backend_address_pool_association" "project" {
  network_interface_id    = azurerm_network_interface.project.id
  ip_configuration_name   = azurerm_network_interface.project.ip_configuration.0.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.project.id
}


resource "azurerm_availability_set" "project" {
  name                = "${var.prefix}-aset"
  location            = azurerm_resource_group.project.location
  resource_group_name = azurerm_resource_group.project.name
  platform_fault_domain_count = 2
  tags = {
  Project = "${var.Project}"
  }
}
