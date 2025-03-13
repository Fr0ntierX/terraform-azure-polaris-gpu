locals {
  sanitized_name = lower(replace(var.name, "/[^a-z0-9]/", "-"))
  vm_name        = "${local.sanitized_name}-vm"
  key_vault_name = "${local.sanitized_name}-vault"
  key_name       = "${local.sanitized_name}-key"

  vnet_id = {
    existing = var.virtualNetworkResourceGroup != "" ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.virtualNetworkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetworkName}" : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetworkName}"
    new      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Network/virtualNetworks/${var.virtualNetworkName}"
  }

  subnet_id = var.virtualNetworkNewOrExisting != "" ? "${local.vnet_id[var.virtualNetworkNewOrExisting]}/subnets/${var.subnetName}" : null

  cloud_init_script = <<-EOT
    #cloud-config
    runcmd:
    - docker login ${var.customWorkloadImageRegistryLoginServer} --username ${var.customWorkloadImageRegistryUsername} --password ${var.customWorkloadImageRegistryPassword}
    - docker network create secure-network
    - docker pull fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polarisProxyImageVersion, "@sha256") ? var.polarisProxyImageVersion : ":${var.polarisProxyImageVersion}"}
    - docker pull ${var.workloadType == "customWorkload" ? var.customWorkloadImageAddress : var.workloadType == "vllmWorkload" ? "fr0ntierxpublicdev.azurecr.io/polaris-llm-gpu-vllm:latest" : "fr0ntierxpublicdev.azurecr.io/polaris-llm-gpu-ollama:latest"}
    - docker login ${var.clientWorkloadImageRegistryLoginServer} --username ${var.clientWorkloadImageRegistryUsername} --password ${var.clientWorkloadImageRegistryPassword}
    - docker pull ${var.clientWorkloadImageAddress}
    - docker pull fr0ntierxpublic.azurecr.io/polaris-azure-skr:latest
    - docker run -p 8081:8081 -d -e PORT=8081 --privileged --network secure-network --volume=/dev/tpmrm0:/dev/tpmrm0 --volume=/sys/kernel/security:/sys/kernel/security --name polaris-azure-skr fr0ntierxpublic.azurecr.io/polaris-azure-skr:latest
    - docker run -d --network secure-network --name polaris-secure-proxy -p ${var.polarisProxyPort}:${var.polarisProxyPort} -e POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION=${lower(tostring(var.polarisProxyEnableInputEncryption))} -e POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION=${lower(tostring(var.polarisProxyEnableOutputEncryption))} -e POLARIS_CONTAINER_ENABLE_CORS=${lower(tostring(var.polarisProxyEnableCORS))} -e POLARIS_CONTAINER_ENABLE_LOGGING=${lower(tostring(var.polarisProxyEnableLogging))} -e POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT=https://sharedweu.weu.attest.azure.net -e POLARIS_CONTAINER_AZURE_SKR_AKV_ENDPOINT=https://${lower(local.key_vault_name)}.${var.keyVaultBaseDomain} -e POLARIS_CONTAINER_AZURE_SKR_KEY_RELEASE_ENDPOINT=http://polaris-azure-skr:8081 -e POLARIS_CONTAINER_KEY_TYPE=azure-skr -e POLARIS_CONTAINER_AZURE_SKR_KID=${local.key_name} -e POLARIS_CONTAINER_WORKLOAD_BASE_URL=http://${var.workloadType == "customWorkload" ? "workload:${var.customWorkloadPort}" : var.workloadType == "vllmWorkload" ? "vllm-workload:8000" : var.clientWorkloadImageAddress == "" ? "ollama:11434" : "client-workload:${var.clientWorkloadPort}"} fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polarisProxyImageVersion, "@sha256") ? var.polarisProxyImageVersion : ":${var.polarisProxyImageVersion}"}
    - >
      docker run -d --network secure-network --name ${
  var.workloadType == "customWorkload"
  ? "workload"
  : var.workloadType == "vllmWorkload"
  ? "vllm-workload"
  : "ollama"
  } ${
  var.workloadType == "customWorkload"
  ? "-p ${var.customWorkloadPort}:${var.customWorkloadPort} ${join(" ", [for env in var.customWorkloadEnvironmentVariables : "-e ${env.name}=${env.value}"])} ${var.customWorkloadImageAddress} ${var.customWorkloadCommand} ${join(" ", var.customWorkloadArguments)}"
  : var.workloadType == "vllmWorkload"
  ? "--restart=always -it --gpus all -p 8000:8000 -e HF_TOKEN=${var.vllmWorkloadHfToken} -e POLARIS_VLLM_MODEL=${var.vllmWorkloadVllmModel} fr0ntierxpublicdev.azurecr.io/polaris-llm-gpu-vllm:latest"
  : "--restart=always -e POLARIS_LLM_OLLAMA_MODEL=${var.ollamaModelName} -p 11434:11434 -it --gpus all fr0ntierxpublicdev.azurecr.io/polaris-llm-gpu-ollama:latest"
}
    - >
      docker run -d --network secure-network --name client-workload -p ${var.clientWorkloadPort}:${var.clientWorkloadPort} ${join(" ", [for env in var.clientWorkloadEnvironmentVariables : "-e ${env.name}=${env.value}"])} ${var.clientWorkloadImageAddress} ${var.clientWorkloadCommand} ${join(" ", var.clientWorkloadArguments)}
  EOT
}

resource "azurerm_resource_group" "main" {
  name     = "${local.sanitized_name}-rg"
  location = var.location
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = local.vm_name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vmSize
  admin_username        = var.adminUsername
  computer_name         = local.vm_name
  zone                  = var.availabilityZone
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_password                  = var.authenticationType == "password" ? var.adminPasswordOrKey : null
  disable_password_authentication = var.authenticationType == "sshPublicKey"

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
    for_each = var.authenticationType == "sshPublicKey" ? [1] : []
    content {
      username   = var.adminUsername
      public_key = var.adminPasswordOrKey
    }
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_network_interface.main]
}
