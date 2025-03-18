# Azure Polaris GPU Terraform Module

This Terraform module deploys a confidential GPU virtual machine on Azure with Polaris proxy for secure inference.

## Features

- Deploys an Azure Confidential VM with GPU (H100)
- Sets up Polaris proxy for secure inference
- Configures containerized workloads (custom, vLLM, Ollama, or TorchServe)
- Creates a Key Vault with secure key release policy
- Configures networking with appropriate security

## Requirements

- Terraform >= 0.14.9
- Azure Provider ~> 4.22.0
- Azure API Provider ~> 2.3.0

## Overview

The Azure Polaris Terraform Module provisions confidential computing resources in Azure with hardware-backed security features. It deploys:

- **Confidential Virtual Machine**: Protected by vTPM, Secure Boot, and hardware-based isolation
- **Polaris Proxy Container**: Exposes a secure service with configurable encryption, CORS, and logging
- **AI Workload Container**: Runs your chosen AI model (custom, vLLM, Ollama, or TorchServe)
- **SKR Sidecar Container**: Handles secure key release protocol for attestation
- **Key Vault**: Provides secure key management backed by hardware security modules

For more detailed information about Polaris, please visit the [Polaris documentation](https://docs.fr0ntierx.com)

## Requirements

| Requirement        | Details                           |
| ------------------ | --------------------------------- |
| Terraform          | >= 1.0.0                          |
| Azure Provider     | >= 4.22.0                         |
| Azure API Provider | >= 2.3.0                          |
| Azure Subscription | Active with necessary permissions |

## Variables

### Core Configuration

| Name            | Type   | Description                 | Default |
| --------------- | ------ | --------------------------- | ------- |
| name            | string | Base name for all resources | N/A     |
| location        | string | Azure region for deployment | N/A     |
| subscription_id | string | Azure subscription ID       | N/A     |

### Authentication and VM Configuration

| Name                  | Type   | Description                     | Default                     |
| --------------------- | ------ | ------------------------------- | --------------------------- |
| admin_username        | string | Username for the VM             | N/A                         |
| admin_password_or_key | string | Password or SSH key             | N/A                         |
| authentication_type   | string | "password" or "sshPublicKey"    | "sshPublicKey"              |
| zone                  | string | Availability Zone for the VM    | "1"                         |
| vm_size               | string | VM size (should be GPU-enabled) | "Standard_NCC40ads_H100_v5" |

### Compute Resources

| Name             | Type   | Description                                   | Default |
| ---------------- | ------ | --------------------------------------------- | ------- |
| container_cpu    | number | CPU cores for main workload container         | 1       |
| container_memory | number | Memory size in GB for main workload container | 4       |

### Networking Configuration

| Name                             | Type         | Description                     | Default         |
| -------------------------------- | ------------ | ------------------------------- | --------------- |
| virtual_network_new_or_existing  | string       | "new", "existing" or ""         | "new"           |
| virtual_network_name             | string       | Name of the virtual network     | "vNet"          |
| virtual_network_resource_group   | string       | Resource group of existing VNet | ""              |
| virtual_network_address_prefixes | list(string) | Address prefixes for the VNet   | ["10.0.0.0/16"] |
| subnet_name                      | string       | Name of the subnet              | "default"       |
| subnet_address_prefix            | string       | Address prefix for the subnet   | "10.0.1.0/24"   |

### Security & Encryption

| Name                                   | Type         | Description                                   | Default       |
| -------------------------------------- | ------------ | --------------------------------------------- | ------------- |
| polaris_proxy_source_ranges            | list(string) | IP ranges allowed to access the Polaris proxy | ["0.0.0.0/0"] |
| polaris_proxy_enable_input_encryption  | bool         | Enable input encryption                       | false         |
| polaris_proxy_enable_output_encryption | bool         | Enable output encryption                      | false         |

### Polaris Proxy Configuration

| Name                         | Type   | Description                       | Default  |
| ---------------------------- | ------ | --------------------------------- | -------- |
| polaris_proxy_image_version  | string | Polaris proxy image version/tag   | "latest" |
| polaris_proxy_port           | number | Port exposed by the Polaris proxy | 3000     |
| polaris_proxy_enable_cors    | bool   | Enable CORS for API endpoints     | false    |
| polaris_proxy_enable_logging | bool   | Enable enhanced logging           | true     |
| maa_endpoint                 | string | Microsoft Attestation endpoint    | ""       |

### Key Vault Configuration

| Name                  | Type   | Description               | Default           |
| --------------------- | ------ | ------------------------- | ----------------- |
| key_vault_base_domain | string | Base domain for Key Vault | "vault.azure.net" |

### Workload Configuration

| Name          | Type   | Description                                                                            | Default |
| ------------- | ------ | -------------------------------------------------------------------------------------- | ------- |
| workload_type | string | Type of workload (customWorkload, vllmWorkload, ollamaWorkload, or torchServeWorkload) | N/A     |

#### Custom Workload Settings

| Name                                        | Type         | Description                   | Default |
| ------------------------------------------- | ------------ | ----------------------------- | ------- |
| custom_workload_image_address               | string       | Container image address       | ""      |
| custom_workload_port                        | number       | Port exposed by the container | 8080    |
| custom_workload_command                     | string       | Command to run                | ""      |
| custom_workload_arguments                   | list(string) | Command arguments             | []      |
| custom_workload_environment_variables       | list(object) | Environment variables         | []      |
| custom_workload_image_registry_login_server | string       | Container registry server     | ""      |
| custom_workload_image_registry_username     | string       | Registry username             | ""      |
| custom_workload_image_registry_password     | string       | Registry password             | ""      |

#### vLLM Settings

| Name                     | Type   | Description       | Default |
| ------------------------ | ------ | ----------------- | ------- |
| vllm_workload_hf_token   | string | HuggingFace token | ""      |
| vllm_workload_vllm_model | string | vLLM model name   | ""      |

#### Ollama Settings

| Name              | Type   | Description          | Default                     |
| ----------------- | ------ | -------------------- | --------------------------- |
| ollama_model_name | string | Ollama model to load | "llama3.2:1b-instruct-q4_0" |

#### TorchServe Settings

| Name              | Type   | Description          | Default |
| ----------------- | ------ | -------------------- | ------- |
| model_archive_url | string | URL to model archive | ""      |

### Container Registry

| Name                  | Type   | Description                  | Default |
| --------------------- | ------ | ---------------------------- | ------- |
| registry_login_server | string | Custom registry login server | ""      |
| registry_username     | string | Custom registry username     | ""      |
| registry_password     | string | Custom registry password     | ""      |

## Architecture

This module provisions a confidential VM with GPU capabilities, running:

1. **Polaris Proxy Container**: Secure API endpoint with optional encryption
2. **Workload Container**: Your AI model (custom, vLLM, Ollama, or TorchServe)
3. **Optional Client Container**: Additional workload that can interact with the main workload
4. **Secure Key Release Container**: Facilitates secure key release for confidential computing

The VM uses hardware-backed security features including vTPM and secure boot to protect your workloads.

## Pre-deployment Requirements

### Authentication and Permissions

This module requires:

1. An authenticated Azure session (via CLI, service principal, or managed identity)
2. The `subscription_id` parameter must match your authenticated session's subscription
3. The authenticated identity must have the following permissions:
   - **Contributor** role on the subscription or resource group
   - **User Access Administrator** role (for managing identities)
   - **Key Vault Administrator** role

### Required Resource Providers

Ensure these Azure resource providers are registered in your subscription:

```bash
az provider register --namespace Microsoft.ContainerInstance
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ManagedIdentity
```

## Usage Examples

### Basic Usage with Custom Workload

```hcl
module "polaris_azure_gpu_module" {
  source = "Fr0ntierX/polaris/azure-gpu"

  subscription_id = "your-subscription-id"

  name     = "polaris-gpu-example"
  location = "eastus2"
  zone     = "2"

  admin_username        = "azureuser"
  authentication_type   = "password"
  admin_password_or_key = "YOUR_PASSWORD"

  polaris_proxy_port          = 3000
  polaris_proxy_image_version = "latest"

  workload_type = "customWorkload"

  custom_workload_image_address = "YOUR_ACR_SERVER/your-llm-image:latest"
  custom_workload_port          = 11434

  custom_workload_image_registry_login_server = "YOUR_ACR_SERVER"
  custom_workload_image_registry_username     = "YOUR_ACR_USERNAME"
  custom_workload_image_registry_password     = "YOUR_ACR_PASSWORD"


}
```

## Deployment Steps

1. Initialize Terraform:

   ```shell
   terraform init
   ```

2. Plan the deployment:

   ```shell
   terraform plan
   ```

3. Apply the configuration:

   ```shell
   terraform apply
   ```

4. Access your Polaris service:
   ```shell
   curl $(terraform output -raw polaris_proxy_endpoint)
   ```

## Notes

- When using private networking, ensure that your Azure subscription has the necessary VNET integration capabilities enabled
- Confidential computing features are region-dependent; check Azure documentation for availability
- For production workloads, consider using Azure DevOps or GitHub Actions for deployment pipelines

## Further Resources

- [Azure Confidential Computing Documentation](https://docs.microsoft.com/azure/confidential-computing/)
- [Azure Container Instances Documentation](https://docs.microsoft.com/azure/container-instances/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
