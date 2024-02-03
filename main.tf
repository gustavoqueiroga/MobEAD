terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Criar Resource Group para todos os recursos
resource "azurerm_resource_group" "rg-tf" {
  name         ="rg-terraform"
  location     = "eastus2"
}
# Windows
resource "azurerm_virtual_network" "vnet01" {
  name                = "vnet-prd01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location
  address_space       = ["10.50.0.0/16"]
}
resource "azurerm_subnet" "sub01" {
  name                 = "sub-prd01"
  resource_group_name  = azurerm_resource_group.rg-tf.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = [ "10.50.1.0/24" ] 
}

resource "azurerm_network_security_group" "nsg01" {
  name                = "nsg-prd01"
  location            = azurerm_resource_group.rg-tf.location
  resource_group_name = azurerm_resource_group.rg-tf.name
  
  security_rule{
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "10.50.1.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg01" {
  subnet_id                 = azurerm_subnet.sub01.id
  network_security_group_id = azurerm_network_security_group.nsg01.id

}

resource "azurerm_public_ip" "pip01" {
  name                = "pip-vmwn01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vnic01" {
  name                = "nic-vm-win01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip01.id
  }
}

resource "azurerm_windows_virtual_machine" "vm01" {
  name                = "vm-win01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location
  size                = "Standard_B2S"
  admin_username      = "admin.tftec"
  admin_password      = "Tftec@2023"

  network_interface_ids = [
    azurerm_network_interface.vnic01.id,
  ]
  source_image_reference {
    publisher        = "MicrosoftWindowsServer"
    offer            = "WindowsServer"
    sku              = "2022-Datacenter"
    version          = "latest"
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }
}
#Linux
resource "azurerm_virtual_network" "vnet02" {
  name                = "vnet-prd02"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location
  address_space       = ["172.16.0.0/16"]
}
resource "azurerm_subnet" "sub02" {
  name                 = "sub-prd02"
  resource_group_name  = azurerm_resource_group.rg-tf.name
  virtual_network_name = azurerm_virtual_network.vnet02.name
  address_prefixes     = [ "172.16.0.0/24" ] 
}
resource "azurerm_network_security_group" "nsg02" {
  name                = "nsg-prd02"
  location            = azurerm_resource_group.rg-tf.location
  resource_group_name = azurerm_resource_group.rg-tf.name
  
  security_rule{
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "172.16.0.0/24"
  }
}
resource "azurerm_subnet_network_security_group_association" "nsg02" {
  subnet_id                 = azurerm_subnet.sub02.id
  network_security_group_id = azurerm_network_security_group.nsg02.id

}

resource "azurerm_public_ip" "pip02" {
  name                = "pip-vmlnx01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vnic02" {
  name                = "nic-vm-lnx01"
  resource_group_name = azurerm_resource_group.rg-tf.name
  location            = azurerm_resource_group.rg-tf.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub02.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip02.id
  }
}

resource "azurerm_linux_virtual_machine" "vm02" {
  name                            = "vm-lnx01"
  resource_group_name             = azurerm_resource_group.rg-tf.name
  location                        = azurerm_resource_group.rg-tf.location
  size                            = "Standard_B2S"
  admin_username                  = "admin.tftec"
  admin_password                  = "Tftec@2023"
  disable_password_authentication = false
  

  network_interface_ids = [
    azurerm_network_interface.vnic02.id,
  ]
  source_image_reference {
    publisher        = "Canonical"
    offer            = "0001-com-ubuntu-server-focal"
    sku              = "20_04-lts"
    version          = "latest"
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }
}