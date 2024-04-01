terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.97.1"
    }
  }
}

provider "azurerm" {
 skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
 features {}
}

resource "azurerm_virtual_network" "k8s_lab_vnet" {
  name                = "k8s-lab-vnet"
  resource_group_name  = azurerm_resource_group.k8s_lab.name
  location            = azurerm_resource_group.k8s_lab.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "k8s_lab_sub" {
  name                 = "k8s-lab-sub"
  resource_group_name  = azurerm_resource_group.k8s_lab.name
  virtual_network_name = azurerm_virtual_network.k8s_lab_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "control" {
  name                = "control-public-ip"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "worker1" {
  name                = "worker1-public-ip"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "worker2" {
  name                = "worker2-public-ip"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "k8s_lab_nsg" {
  name                = "k8s-lab-nsg"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name

  security_rule {
    name                       = "Allow_Ports"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["22","80","8080","6443","10250","10257","10259","2379-2380","30000-32767"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "control" {
  name                = "control-nic"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name

  ip_configuration {
    name                          = "control-ip-config"
    subnet_id                     = azurerm_subnet.k8s_lab_sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.control.id
  }
}

resource "azurerm_network_interface" "worker1" {
  name                = "worker1-nic"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name

  ip_configuration {
    name                          = "worker1-ip-config"
    subnet_id                     = azurerm_subnet.k8s_lab_sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker1.id
  }
}

resource "azurerm_network_interface" "worker2" {
  name                = "worker2-nic"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name

  ip_configuration {
    name                          = "worker2-ip-config"
    subnet_id                     = azurerm_subnet.k8s_lab_sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker2.id
  }
}

# Connect the security group to the control network interface
resource "azurerm_network_interface_security_group_association" "control_nisg" {
  network_interface_id      = azurerm_network_interface.control.id
  network_security_group_id = azurerm_network_security_group.k8s_lab_nsg.id
}

# Connect the security group to the worker1 network interface
resource "azurerm_network_interface_security_group_association" "worker1_nisg" {
  network_interface_id      = azurerm_network_interface.worker1.id
  network_security_group_id = azurerm_network_security_group.k8s_lab_nsg.id
}

# Connect the security group to the worker2 network interface
resource "azurerm_network_interface_security_group_association" "worker2_nisg" {
  network_interface_id      = azurerm_network_interface.worker2.id
  network_security_group_id = azurerm_network_security_group.k8s_lab_nsg.id
}

resource "azurerm_linux_virtual_machine" "control" {
  name                            = "control-vm"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  network_interface_ids           = [azurerm_network_interface.control.id]
  size                            = "Standard_D2s_v3"// Or any other appropriate size
  admin_username                  = "demouser"
  admin_password                  = "P@ssw0rd123!" // Or use SSH keys
  custom_data = filebase64("./azure-user-data-control.sh")
  disable_password_authentication = false
  
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

resource "azurerm_linux_virtual_machine" "worker1" {
  name                            = "worker1-vm"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  network_interface_ids           = [azurerm_network_interface.worker1.id]
  size                            = "Standard_D2s_v3"
  admin_username                  = "demouser"
  admin_password                  = "P@ssw0rd123!"
  custom_data = filebase64("./azure-user-data-workers.sh")
  disable_password_authentication = false

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

resource "azurerm_linux_virtual_machine" "worker2" {
  name                            = "worker2-vm"
  location            = azurerm_resource_group.k8s_lab.location
  resource_group_name = azurerm_resource_group.k8s_lab.name
  network_interface_ids           = [azurerm_network_interface.worker2.id]
  size                            = "Standard_D2s_v3"
  admin_username                  = "demouser"
  admin_password                  = "P@ssw0rd123!"
  custom_data = filebase64("./azure-user-data-workers.sh")
  disable_password_authentication = false

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