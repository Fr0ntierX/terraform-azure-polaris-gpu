data "azurerm_virtual_network" "existing" {
  name                = var.virtual_network_name
  resource_group_name = var.virtual_network_resource_group
}

output "available_subnets" {
  value = data.azurerm_virtual_network.existing.subnets
  description = "List of available subnets in the virtual network"
}

data "azurerm_subnet" "existing" {
  count                = var.subnet_name != "" ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = var.virtual_network_resource_group
}


resource "azurerm_network_interface" "main" {
  name                = "${local.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = length(data.azurerm_subnet.existing) > 0 ? data.azurerm_subnet.existing[0].id : null
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  depends_on = [
    azurerm_public_ip.main
  ]
}

resource "azurerm_public_ip" "main" {
  name                = "${local.sanitized_name}-vm-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "main" {
  name                = "${local.sanitized_name}-vm-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*" 
    destination_port_range     = tostring(var.polaris_proxy_port)
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
