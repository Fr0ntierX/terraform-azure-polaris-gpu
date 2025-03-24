locals {
  sanitized_name = lower(replace(var.name, "/[^a-z0-9]/", "-"))
  vm_name        = "${local.sanitized_name}-vm"
  key_vault_name = "${local.sanitized_name}-vault"
  key_name       = "${local.sanitized_name}-key"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.sanitized_name}-rg"
  location = var.location
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = local.vm_name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  computer_name         = local.vm_name
  zone                  = var.zone
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_password                  = var.authentication_type == "password" ? var.admin_password_or_key : null
  disable_password_authentication = var.authentication_type == "sshPublicKey"

  custom_data = base64encode(local.cloud_init_script)

  vtpm_enabled        = true
  secure_boot_enabled = true

  os_disk {
    name                 = "${local.sanitized_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 120

    security_encryption_type = "VMGuestStateOnly"
  }

  source_image_id = "/communityGalleries/polaris-e3c4198b-d4a4-42b2-b41d-25368bd3d7a1/images/polaris-confidential-gpu-h100-2204/versions/latest"

  dynamic "admin_ssh_key" {
    for_each = var.authentication_type == "sshPublicKey" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_password_or_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_network_interface.main]
}
