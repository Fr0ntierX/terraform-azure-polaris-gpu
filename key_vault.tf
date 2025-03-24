resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  
  enable_rbac_authorization = false
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_virtual_machine.main.identity[0].principal_id
    
    key_permissions = [
      "Get",
      "Release"
    ]
  }
  
  depends_on = [azurerm_linux_virtual_machine.main]
}

resource "azapi_resource" "key" {
  type      = "Microsoft.KeyVault/vaults/keys@2023-02-01"
  name      = local.key_name
  parent_id = azurerm_key_vault.main.id

  body = {
    properties = {
      kty = "RSA-HSM"
      keyOps = [
        "encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"
      ]
      attributes = {
        enabled = true
        exportable = true
      }
      release_policy = {
        contentType = "application/json; charset=utf-8"
        data = base64encode(jsonencode({
          version = "1.0.0"
          anyOf = [
            {
              authority = "https://sharedweu.weu.attest.azure.net"
              allOf = [
                {
                  claim = "x-ms-isolation-tee.x-ms-attestation-type"
                  equals = "sevsnpvm"
                },
                {
                  claim = "x-ms-isolation-tee.x-ms-compliance-status"
                  equals = "azure-compliant-cvm"
                }
              ]
            }
          ]
        }))
      }
    }
  }

  schema_validation_enabled = false
  depends_on = [azurerm_key_vault.main]
}
