provider "azurerm" {
  features {}
}

# Define the Resource Group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Define the Virtual Network
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Define the Subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the Public IP Address
resource "azurerm_public_ip" "example" {
  name                         = "example-public-ip"
  location                     = azurerm_resource_group.example.location
  resource_group_name          = azurerm_resource_group.example.name
  allocation_method            = "Static"  # Set to "Static" for a fixed IP address

  tags = {
    environment = "production"
  }
}

# Define the Network Interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  ip_configuration {
    name                          = "example-nic-config"
    private_ip_address_allocation = "Dynamic"  # Dynamic private IP
    public_ip_address_id          = azurerm_public_ip.example.id  # Attach the public IP
  }

  tags = {
    environment = "production"
  }
}

# Define the Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.example.id
  ]

  image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "production"
  }
}

# Define a Managed Disk for the VM (optional, OS disk is already created)
resource "azurerm_managed_disk" "additional_disk" {
  name                 = "example-additional-disk"
  resource_group_name  = azurerm_resource_group.example.name
  location             = azurerm_resource_group.example.location
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = 50  # Size in GB
}

# Attach the additional disk to the VM
resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.additional_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.example.id
  lun                 = 1  # LUN (Logical Unit Number), 1 for additional disk
  caching             = "ReadWrite"
  disk_size_gb = 5  # Size in GB
}
