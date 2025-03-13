# Azure Polaris GPU Terraform Module

This Terraform module deploys a confidential GPU virtual machine on Azure with Polaris proxy for secure inference.

## Features

- Deploys an Azure Confidential VM with GPU (H100)
- Sets up Polaris proxy for secure inference
- Configures containerized workloads (custom, vLLM, or Ollama)
- Creates a Key Vault with secure key release policy
- Configures networking with appropriate security

## Requirements

- Terraform >= 0.14.9
- Azure subscription with GPU quota
- SSH key pair for VM authentication

## Overview

The Azure Polaris Terraform Module provisions confidential computing containers in Azure Container Instances (ACI) with optional Azure Key Vault integration. It deploys three containers:

- **Polaris Proxy:** Exposes a secure service with configurable encryption, CORS, and logging.
- **Client Workload:** Runs your custom workload application.
- **SKR Sidecar:** (When Key Vault is enabled) Handles secure key release protocol.

Optional integration with Azure Key Vault enables enhanced security through hardware attestation and secure key release policies.

For more detailed information about Polaris, please visit the [Polaris documentation](https://docs.fr0ntierx.com)

## Requirements

| Requirement        | Details                           |
| ------------------ | --------------------------------- |
| Terraform          | >= 1.0.0                          |
| Azure Provider     | >= 4.22.0                         |
| Azure API Provider | >= 2.3.0                          |
| Azure Subscription | Active with necessary permissions |

## Key Differences Between Standard and Enhanced Modes

- **Standard Mode:** Basic container group with Docker containers.
- **Enhanced Mode:** In addition to the standard setup, it enables Azure Key Vault integration, providing enhanced security via HSM-backed key vault and secure key release, which may incur additional costs.

## Pricing Considerations

Be aware that deploying with `enable_key_vault = true` may incur additional costs compared to the standard deployment. This mode leverages Azure Key Vault Premium tier and confidential computing features, which have their own pricing. Please refer to Azure pricing documentation for detailed cost estimates.

## Variables

### Core Configuration

| Name            | Type   | Description                 | Default |
| --------------- | ------ | --------------------------- | ------- |
| name            | string | Base name for all resources | N/A     |
| location        | string | Azure region for deployment | N/A     |
| subscription_id | string | Azure subscription ID       | N/A     |

### Compute Resources

| Name             | Type   | Description                                   | Default |
| ---------------- | ------ | --------------------------------------------- | ------- |
| container_cpu    | number | CPU cores for main workload container         | 1       |
| container_memory | number | Memory size in GB for main workload container | 4       |

### Networking Configuration

| Name                  | Type         | Description                                | Default         |
| --------------------- | ------------ | ------------------------------------------ | --------------- |
| new_vnet_enabled      | bool         | Whether to create a new virtual network    | true            |
| networking_type       | string       | Networking type (Public or Private)        | Public          |
| dns_name_label        | string       | DNS name label for public IP               | ""              |
| vnet_name             | string       | Name of existing virtual network           | ""              |
| vnet_resource_group   | string       | Resource group of existing virtual network | ""              |
| vnet_address_space    | list(string) | Address space for new virtual network      | ["10.0.0.0/16"] |
| subnet_name           | string       | Subnet name                                | "default"       |
| subnet_address_prefix | string       | Subnet address prefix                      | "10.0.1.0/24"   |

### Security & Encryption

| Name                                   | Type         | Description                                   | Default       |
| -------------------------------------- | ------------ | --------------------------------------------- | ------------- |
| enable_key_vault                       | bool         | Enable key vault integration                  | true          |
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

### Workload Configuration

| Name               | Type         | Description                            | Default |
| ------------------ | ------------ | -------------------------------------- | ------- |
| workload_image     | string       | Container image for the workload       | N/A     |
| workload_port      | number       | Port exposed by the workload           | 8000    |
| workload_env_vars  | map(string)  | Environment variables for the workload | {}      |
| workload_arguments | list(string) | Command arguments for the workload     | []      |

### Container Registry

| Name                  | Type   | Description                  | Default |
| --------------------- | ------ | ---------------------------- | ------- |
| registry_login_server | string | Custom registry login server | ""      |
| registry_username     | string | Custom registry username     | ""      |
| registry_password     | string | Custom registry password     | ""      |

## Module Modes

The module offers two modes depending on the value of `enable_key_vault`:

| Feature         | Standard Mode (enable_key_vault = false) | Enhanced Mode (enable_key_vault = true)             |
| --------------- | ---------------------------------------- | --------------------------------------------------- |
| Container Group | Standard container group                 | Confidential container group with SKR sidecar       |
| Authentication  | Basic container identity                 | System-assigned managed identity                    |
| Key Management  | Ephemeral keys                           | Azure Key Vault integration with secure key release |
| Security        | Container isolation                      | Hardware attestation and secure key release         |

## Outputs

| Output Name          | Description                                           |
| -------------------- | ----------------------------------------------------- |
| resource_group_name  | Name of the resource group                            |
| container_group_name | Name of the container group                           |
| container_group_ip   | IP address of the container group (public networking) |
| container_group_fqdn | FQDN of the container group (public networking)       |
| key_vault_name       | Name of the key vault (when enabled)                  |
| key_vault_uri        | URI of the key vault (when enabled)                   |
| key_name             | Name of the key (when enabled)                        |

## Architecture

The module provisions the following resources:

- **Resource Group:** Contains all deployed resources.
- **Container Registry:** Azure Container Registry to store and manage container images.
- **Container Group:** Azure Container Instances with 2-3 containers (depending on mode):
  - **Polaris Proxy Container:** Securely exposes your service.
  - **Client Workload Container:** Runs your application code.
  - **SKR Sidecar Container:** (Enhanced mode only) Handles secure key release protocol.
- **Virtual Network:** (Optional) Network infrastructure for private networking.
- **Network Security Group:** (Optional) Controls traffic to private containers.
- **Key Vault:** (Enhanced mode only) Manages cryptographic keys with secure attestation.

## Pre-deployment Requirements

### Authentication and Permissions

This module requires:

1. An authenticated Azure session (via CLI, service principal, or managed identity)
2. The `subscription_id` parameter must match your authenticated session's subscription
3. The authenticated identity must have the following permissions:
   - **Contributor** role on the subscription or resource group
   - **User Access Administrator** role (for managing identities)
   - **Key Vault Administrator** role (if using `enable_key_vault = true`)

### Required Resource Providers

Ensure these Azure resource providers are registered in your subscription:

```bash
az provider register --namespace Microsoft.ContainerInstance
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ManagedIdentity
```

## Usage Example

```hcl
module "polaris_azure_module" {
  source = "path/to/module"

  subscription_id = "your-subscription-id"

  name     = "polaris-example"
  location = "West Europe"

  # Security & Encryption
  enable_key_vault = true

  # Container Resources
  container_memory = 4
  container_cpu    = 2

  # Networking Configuration
  networking_type  = "Public"
  new_vnet_enabled = true
  dns_name_label   = "polaris-example-app"

  # Polaris Proxy Configuration
  polaris_proxy_port                  = 3000
  polaris_proxy_enable_input_encryption  = true
  polaris_proxy_enable_output_encryption = true
  polaris_proxy_enable_cors           = true
  polaris_proxy_enable_logging        = true

  # Workload Configuration
  workload_image = "your-registry.azurecr.io/your-workload:latest"
  workload_port  = 8000

  workload_env_vars = {
    "API_KEY" = "your-api-key"
    "DEBUG"   = "true"
  }
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
   curl http://$(terraform output -raw container_group_fqdn):3000/
   ```

## Security Recommendations

1. Use private networking when possible
2. Restrict IP access using `polaris_proxy_source_ranges`
3. Enable Key Vault integration for production workloads
4. Regularly rotate credentials and update container images
5. Use environment variables or Azure Key Vault to store sensitive credentials like registry passwords
6. Consider using Azure Managed Identities for registry access instead of username/password

## Notes

- When using private networking, ensure that your Azure subscription has the necessary VNET integration capabilities enabled
- Confidential computing features are region-dependent; check Azure documentation for availability
- For production workloads, consider using Azure DevOps or GitHub Actions for deployment pipelines

## Further Resources

- [Azure Confidential Computing Documentation](https://docs.microsoft.com/azure/confidential-computing/)
- [Azure Container Instances Documentation](https://docs.microsoft.com/azure/container-instances/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
