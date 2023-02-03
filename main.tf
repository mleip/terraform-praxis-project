#
# Ressourcengruppe erstellen
###########################################################################################################################
resource "azurerm_resource_group" "cicdproject" {
  name     = "michael-leipner-rg"
  location = "West Europe"
}
#
# 
############################################################################################################################
resource "azurerm_virtual_network" "cinetwork" {
  name                = "cicdproject-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.cicdproject.location
  resource_group_name = azurerm_resource_group.cicdproject.name
}
#
# 
############################################################################################################################
resource "azurerm_subnet" "cisubnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.cicdproject.name
  virtual_network_name = azurerm_virtual_network.cinetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}
#
# jenkins public ip
############################################################################################################################
resource "azurerm_public_ip" "jenkinspublicip" {
  name                = "jenkins-public-ip"
  resource_group_name = azurerm_resource_group.cicdproject.name
  location            = azurerm_resource_group.cicdproject.location
  allocation_method   = "Dynamic"
}
#
# webserver public ip
############################################################################################################################
resource "azurerm_public_ip" "webserverpublicip" {
  name                = "webserver-public-ip"
  resource_group_name = azurerm_resource_group.cicdproject.name
  location            = azurerm_resource_group.cicdproject.location
  allocation_method   = "Dynamic"
}
#
# interface jenkins
############################################################################################################################
resource "azurerm_network_interface" "jenkinsnic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.cicdproject.location
  resource_group_name = azurerm_resource_group.cicdproject.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cisubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkinspublicip.id
  }

  depends_on = [
    azurerm_public_ip.jenkinspublicip
  ]
}
#
# interface webserver
############################################################################################################################
resource "azurerm_network_interface" "webservernic" {
  name                = "webserver-nic"
  location            = azurerm_resource_group.cicdproject.location
  resource_group_name = azurerm_resource_group.cicdproject.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cisubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserverpublicip.id
  }

  depends_on = [
    azurerm_public_ip.webserverpublicip
  ]
}
#
# sicherheitsgruppe 
############################################################################################################################
resource "azurerm_network_security_group" "cicdproject" {
  name                = "cicdproject-nsg"
  location            = azurerm_resource_group.cicdproject.location
  resource_group_name = azurerm_resource_group.cicdproject.name
}
#
# sshd sicherheitsregel
############################################################################################################################
resource "azurerm_network_security_rule" "sshd" {
  name                        = "sshd"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cicdproject.name
  network_security_group_name = azurerm_network_security_group.cicdproject.name
}
#
# web sicherheitsregel
############################################################################################################################
resource "azurerm_network_security_rule" "web" {
  name                        = "web"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cicdproject.name
  network_security_group_name = azurerm_network_security_group.cicdproject.name
}
#
# 
############################################################################################################################
resource "azurerm_network_security_rule" "allout" {
  name                        = "web"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cicdproject.name
  network_security_group_name = azurerm_network_security_group.cicdproject.name
}
#
# 
############################################################################################################################
resource "azurerm_network_interface_security_group_association" "jenkinsnsg" {
  network_interface_id      = azurerm_network_interface.jenkinsnic.id
  network_security_group_id = azurerm_network_security_group.cicdproject.id
}
#
# 
############################################################################################################################
resource "azurerm_network_interface_security_group_association" "webservernsg" {
  network_interface_id      = azurerm_network_interface.webservernic.id
  network_security_group_id = azurerm_network_security_group.cicdproject.id
}
#
# virtuelle maschine erstellen jenkins
############################################################################################################################
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "jenkins-vm"
  resource_group_name = azurerm_resource_group.cicdproject.name
  location            = azurerm_resource_group.cicdproject.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.jenkinsnic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./sshkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
#
# virtuelle maschine webserver
#############################################################################################################################
resource "azurerm_linux_virtual_machine" "webserver" {
  name                = "webserver-vm"
  resource_group_name = azurerm_resource_group.cicdproject.name
  location            = azurerm_resource_group.cicdproject.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.webservernic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./sshkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}