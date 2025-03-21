# Azure Polaris GPU Terraform Module

This Terraform module deploys a Confidential GPU Virtual Machine (H100) on Azure, preconfigured with:  
- Polaris Proxy for secure inference  
- Optional AI workloads (custom, vLLM, Ollama, TorchServe)  
- Hardware-backed Key Vault integration for secure key release  
- Configurable networking with NSG rules

## Overview
1. **VM Deployment (H100)**: Creates a confidential VM with GPU (H100), enabling vTPM and secure boot.  
2. **Polaris Proxy**: Exposes a secure endpoint to handle encrypted requests.  
3. **AI Workload**: Runs your chosen containerized model, e.g., LLaMA, TorchServe, or any custom container.  
4. **Optional Client Workload**: A container to interact with the main workload.  
5. **Azure Key Vault**: Managed HSM key creation for secure key release (policy-based attestation).

## Requirements
- Terraform ≥ 1.0.0  
- Azure Provider ≥ 4.22.0  
- Azure API Provider ≥ 2.3.0  
- Active Azure subscription with the Microsoft.Network, Microsoft.KeyVault, Microsoft.ManagedIdentity, and Microsoft.Compute resource providers registered.

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

### Workload Configuration

#### Custom Workload

| Name                   | Type         | Description                                                | Default |
| ---------------------- | ------------ | ---------------------------------------------------------- | ------- |
| custom_workload        | object       | Configuration for custom workload                          | N/A     |
| - image_address        | string       | Container image address                                    | N/A     |
| - port                 | number       | Port exposed by the container                              | 8080    |
| - command              | string       | Optional command to run                                    | ""      |
| - arguments            | list(string) | Optional command arguments                                 | []      |
| - environment_variables| list(object) | Optional environment variables                             | []      |
| - registry             | object       | Optional container registry configuration                  | null    |
|   - login_server       | string       | Registry login server                                      | ""      |
|   - username           | string       | Registry username                                          | ""      |
|   - password           | string       | Registry password                                          | ""      |

#### vLLM Workload

| Name                   | Type   | Description            | Default |
| ---------------------- | ------ | ---------------------- | ------- |
| vllm_workload          | object | vLLM workload config   | N/A     |
| - hf_token             | string | HuggingFace token      | ""      |
| - vllm_model           | string | vLLM model name        | ""      |

#### Ollama Workload

| Name                   | Type   | Description               | Default                     |
| ---------------------- | ------ | ------------------------- | --------------------------- |
| ollama_workload        | object | Ollama workload config    | N/A                         |
| - model_name           | string | Ollama model to load      | "llama3.2:1b-instruct-q4_0" |

#### TorchServe Workload

| Name                   | Type   | Description               | Default |
| ---------------------- | ------ | ------------------------- | ------- |
| torch_serve_workload   | object | TorchServe workload config| N/A     |
| - model_archive_url    | string | URL to model archive      | ""      |

#### Client Workload 

| Name                   | Type         | Description                                                | Default |
| ---------------------- | ------------ | ---------------------------------------------------------- | ------- |
| client_workload        | object       | Configuration for optional client workload                 | N/A     |
| - image_address        | string       | Container image address                                    | ""      |
| - port                 | number       | Port exposed by the container                              | 8080    |
| - command              | string       | Optional command to run                                    | ""      |
| - arguments            | list(string) | Optional command arguments                                 | []      |
| - environment_variables| list(object) | Optional environment variables                             | []      |
| - registry             | object       | Optional container registry configuration                  | null    |
|   - login_server       | string       | Registry login server                                      | ""      |
|   - username           | string       | Registry username                                          | ""      |
|   - password           | string       | Registry password                                          | ""      |

### Networking Configuration

| Name                           | Type   | Description                                                   | Default |
| ------------------------------ | ------ | ------------------------------------------------------------- | ------- |
| virtual_network_name           | string | Name of the existing virtual network to use                   | N/A     |
| virtual_network_resource_group | string | Resource group containing the existing virtual network        | N/A     |
| subnet_name                    | string | Name of the existing subnet within the virtual network        | N/A     |

### Polaris Proxy Configuration

| Name                                | Type         | Description                                | Default     |
| ----------------------------------- | ------------ | ------------------------------------------ | ----------- |
| polaris_proxy_image_version         | string       | Polaris proxy image version/tag            | "latest"    |
| polaris_proxy_port                  | number       | Port exposed by the Polaris proxy          | 3000        |
| polaris_proxy_enable_cors           | bool         | Enable CORS for API endpoints              | false       |
| polaris_proxy_enable_input_encryption| bool        | Enable encryption for input data           | false       |
| polaris_proxy_enable_output_encryption| bool       | Enable encryption for output data          | false       |
| polaris_proxy_enable_logging        | bool         | Enable enhanced logging                    | true        |
| polaris_proxy_source_ranges         | list(string) | IP ranges allowed to access Polaris proxy  | ["0.0.0.0/0"]|
| maa_endpoint                        | string       | URL for Microsoft Attestation service      | ""          |

### Key Vault Configuration

| Name                  | Type   | Description               | Default           |
| --------------------- | ------ | ------------------------- | ----------------- |
| key_vault_base_domain | string | Base domain for Key Vault | "vault.azure.net" |


## Detailed Configuration & Examples

### Container Architecture

The module deploys several containerized applications on the H100 VM:

- **Polaris Proxy Container**: Front-facing service that handles API requests, manages authentication, encryption, and routes requests to the workload container. Exposes configurable port (default: 3000).

- **Main Workload Container**: Runs one of the following AI frameworks:
  - **Custom Workload**: Your custom container image with ML model
  - **vLLM**: Optimized container for serving LLMs from HuggingFace with vLLM
  - **Ollama**: Local LLM serving with the Ollama framework
  - **TorchServe**: PyTorch model serving framework

- **Client Workload Container** (Optional): Additional application that interacts with the main workload. Examples include:
  - API frontends
  - Preprocessing services
  - Data anonymization layers
  - Result formatters

- **Secure Key Release (SKR) Container**: Facilitates secure key management with Azure Key Vault, validating the confidential VM's attestation before accessing encryption keys.

### VM Configuration & Security

- **Confidential Computing**: The VM is deployed with AMD SEV-SNP confidential computing features.
- **vTPM & Secure Boot**: Hardware-backed security features are enabled by default.
- **Disk Encryption**: OS disk uses VMGuestStateOnly encryption mode.
- **Network Security**: NSG rules limit access to SSH (22) and the Polaris Proxy port.
- **System Managed Identity**: VM gets an identity for secure interaction with Key Vault.

### Key Management

- **HSM-Backed Keys**: Keys stored in Azure Key Vault's Hardware Security Modules.
- **Attestation Policy**: Keys are only released to validated confidential environments.
- **Key Vault Access Control**: The VM's managed identity receives minimal permissions (Get, Release).

### Authentication and Permissions

To deploy this module you need:
1. Azure credentials with sufficient permissions:
   - **Contributor** role on the subscription or resource group
   - **User Access Administrator** role for managing identities
   - **Key Vault Administrator** role for key vault operations

2. Required Resource Providers:
   ```bash
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.KeyVault
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.ManagedIdentity
   ```

3. An existing Virtual Network and subnet.


## Example
```hcl
module "polaris_azure_gpu_module" {
  source = "../"

  subscription_id = "YOUR-SUBSCRIPTION-ID"
  name            = "polaris-h100"
  location        = "eastus2"
  zone            = "2"

  admin_username        = "azureuser"
  admin_password_or_key = "MY_PASSWORD"
  authentication_type   = "password"

  virtual_network_name           = "my-precreated-vnet"
  virtual_network_resource_group = "my-network-rg"
  subnet_name                    = "my-subnet"
  
  custom_workload = {
    image_address = "example.azurecr.io/custom-workload:latest"
    port          = 11434
    registry = {
      login_server = "example.azurecr.io"
      username     = "registry_user"
      password     = "registry_password"
    }
  }

  polaris_proxy_enable_input_encryption = true
  polaris_proxy_enable_output_encryption = true
}
```

## Further Info
- [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/)
- [Azure Key Vault Documentation](https://learn.microsoft.com/azure/key-vault/)
- [Azure GPU VM Sizes](https://learn.microsoft.com/azure/virtual-machines/sizes-gpu)
