resource "azurerm_resource_group" "michael-leipner-project" {
  name     = "michael-leipner-project"
  location = "West Europe"
}

resource "azurerm_virtual_network" "michael-project" {
  name                = "michael-project-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.michael-leipner-project.location
  resource_group_name = azurerm_resource_group.michael-leipner-project.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.michael-leipner-project.name
  virtual_network_name = "michael-project-network"
  address_prefixes     = ["10.0.2.0/24"]
}

#VM1

resource "azurerm_public_ip" "jenkins-vm-public_ip" {
  name                = "jenkins-vm-public_ip"
  resource_group_name = azurerm_resource_group.michael-leipner-project.name
  location            = "West Europe"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "michael-project-nic1" {
  name                = "michael-project-nic1"
  location            = "West Europe"
  resource_group_name = "michael-leipner-project"

  ip_configuration {
    name                          = "jenkins-vm-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jenkins-vm-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "jenkins-vm" {
  name                = "jenkins-vm"
  resource_group_name = "michael-leipner-project"
  location            = "West Europe"
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "Test123456."
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.michael-project-nic1.id]
  
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


#VM2
resource "azurerm_public_ip" "server-vm-public_ip" {
  name                = "server-vm-public_ip"
  resource_group_name = "michael-leipner-project"
  location            = "West Europe"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "michael-project-nic2" {
  name                = "michael-project-nic2"
  location            = "West Europe"
  resource_group_name = "michael-leipner-project"

  ip_configuration {
    name                          = "server-vm-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.server-vm-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "server-vm" {
  name                = "server-vm"
  resource_group_name = "michael-leipner-project"
  location            = "West Europe"
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_password      = "Test123456."
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.michael-project-nic2.id]

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
