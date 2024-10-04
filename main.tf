provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}


##### describe VNet client  ########

resource "azurerm_virtual_network" "vnet-client" {
  name                = "vnet-client"
  address_space       = ["10.0.0.0/24"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

}

###### describe Sbnet Client #######

resource "azurerm_subnet" "subnet-client" {
  name                 = "subnet-client"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-client.name
  address_prefixes     = ["10.0.0.16/28"]
}


###### describe Vnet Server ##########

resource "azurerm_virtual_network" "vnet-server" {
  name                = "vnet-server"
  address_space       = ["192.168.0.0/24"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

}

####### describe Sbnet Server #########

resource "azurerm_subnet" "subnet-server" {
  name                 = "subnet-server"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-server.name
  address_prefixes     = ["192.168.0.16/28"]
}



######  describe NIC ##########


##### NIC Client ubuntu ###

resource "azurerm_public_ip" "my_public_ip" {
  name                = "MyPublicIP"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "my_nic" {
  name                = "Nic_Ubuntu"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Nic_Ubuntu_Config"
    subnet_id                     = azurerm_subnet.subnet-client.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_public_ip.id
  }
}



####  NIC client windows ###

resource "azurerm_public_ip" "win-ipp" {
  name                = "win-ipp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}



resource "azurerm_network_interface" "nic-winclt" {
  name                = "nic-winclt"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-winclt"
    subnet_id                     = azurerm_subnet.subnet-client.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.win-ipp.id
  }
}




### NIC client debian ####

resource "azurerm_public_ip" "debian-ipp" {
  name                = "clt-ipp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}



resource "azurerm_network_interface" "nic-debianclt" {
  name                = "nic-debianclt"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-debianclt"
    subnet_id                     = azurerm_subnet.subnet-client.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.debian-ipp.id
  }
}


##### NIC server Nginx ###

resource "azurerm_network_interface" "nic-srv-nginx" {
  name                = "nic-srv-nginx"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-srv-nginx"
    subnet_id                     = azurerm_subnet.subnet-server.id
    private_ip_address_allocation = "Dynamic"
  }
}


###### NIC reverse Proxy #####

resource "azurerm_network_interface" "nic-reproxy" {
  name                = "nic-reproxy"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-reproxy"
    subnet_id                     = azurerm_subnet.subnet-server.id
    private_ip_address_allocation = "Dynamic"
  }
}



######## NSG #################

resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "NSG-Win"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name


  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}




##### generate client with Packer ########


### debian

data "azurerm_image" "main" {
  name                = var.packer_image_debian
  resource_group_name = data.azurerm_resource_group.rg.name
}

### Nginx server

data "azurerm_image" "server" {
  name                = var.packer_image_nginx
  resource_group_name = data.azurerm_resource_group.rg.name
}

### Nginx Proxy

data "azurerm_image" "proxy" {
  name                = var.packer_image_nginx
  resource_group_name = data.azurerm_resource_group.rg.name
}

##### create VM Ubuntu ##############

resource "azurerm_linux_virtual_machine" "Ubuntu" {
  name                  = "Ubuntu-vm"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "useradmin"
  network_interface_ids = [azurerm_network_interface.my_nic.id]

  admin_ssh_key {
    username   = "useradmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "Ubuntu_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


##### create VM Windows #################

resource "azurerm_windows_virtual_machine" "winVM" {
  name                  = "winVM"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic-winclt.id]

  admin_username = "adminuser"
  admin_password = "P@ssw0rd123!"

  size          = "Standard_DS2_v2"
  computer_name = "myVM"

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}


##### create VM Debian ###################

resource "azurerm_linux_virtual_machine" "debian-clt" {
  name                            = "debian-clt"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "admindebian"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic-debianclt.id]
  source_image_id                 = data.azurerm_image.main.id


  admin_ssh_key {
    username   = "admindebian"
    public_key = file("C:/Users/Apprenant/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


}

######## create VM server Nginx ############

resource "azurerm_linux_virtual_machine" "nginx-srv" {
  name                            = "nginx-srv"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "adminginx"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic-srv-nginx.id]
  source_image_id                 = data.azurerm_image.server.id

  admin_ssh_key {
    username   = "adminginx"
    public_key = file("C:/Users/Apprenant/.ssh/id_rsa.pub")
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}


########## create VM reverse Proxy Nginx ########

resource "azurerm_linux_virtual_machine" "revproxy-nginx" {
  name                            = "revproxy-nginx"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = "adminproxy"
  network_interface_ids           = [azurerm_network_interface.nic-reproxy.id]
  disable_password_authentication = true
  computer_name                   = "Nginx-reverse-proxy"
  source_image_id                 = data.azurerm_image.server.id

  admin_ssh_key {
    username   = "adminproxy"
    public_key = file("C:/Users/Apprenant/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


}




