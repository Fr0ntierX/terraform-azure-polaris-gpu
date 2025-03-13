# Core Configuration
variable "name" {
  type        = string
  description = "Base name for all resources"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

# Authentication and VM Configuration
variable "adminUsername" {
  type        = string
  description = "User name for the Virtual Machine"
}

variable "adminPasswordOrKey" {
  type        = string
  sensitive   = true
  description = "Password or SSH key for the Virtual Machine"
}

variable "authenticationType" {
  type        = string
  default     = "sshPublicKey"
  description = "Type of authentication to use on the Virtual Machine"
  validation {
    condition     = contains(["password", "sshPublicKey"], var.authenticationType)
    error_message = "The authenticationType must be either 'password' or 'sshPublicKey'"
  }
}

variable "availabilityZone" {
  type        = string
  default     = "1"
  description = "Availability Zone for the VM"
}

variable "vmSize" {
  type        = string
  default     = "Standard_NCC40ads_H100_v5"
  description = "The size of the VM"
}

variable "imageId" {
  type        = string
  default     = "/CommunityGalleries/polaris-e3c4198b-d4a4-42b2-b41d-25368bd3d7a1/Images/polaris-confidential-gpu-h100-2204/Versions/latest"
  description = "The source image for the VM"
}

# Workload Types
variable "workloadType" {
  type        = string
  description = "Type of workload to run (customWorkload, vllmWorkload, or ollamaWorkload)"
  validation {
    condition     = contains(["customWorkload", "vllmWorkload", "ollamaWorkload"], var.workloadType)
    error_message = "The workloadType must be one of: customWorkload, vllmWorkload, ollamaWorkload"
  }
}

# Client Workload Configuration
variable "clientWorkloadImageAddress" {
  type        = string
  default     = ""
  description = "Container image address for client workload"
}

variable "clientWorkloadPort" {
  type        = number
  default     = 8080
  description = "Port exposed by the client workload container"
}

variable "clientWorkloadCommand" {
  type        = string
  default     = ""
  description = "Command for client workload container"
}

variable "clientWorkloadArguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for client workload container"
}

variable "clientWorkloadEnvironmentVariables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Environment variables for client workload container"
}

variable "clientWorkloadImageRegistryLoginServer" {
  type        = string
  default     = ""
  description = "Registry login server for client workload image"
}

variable "clientWorkloadImageRegistryUsername" {
  type        = string
  default     = ""
  description = "Registry username for client workload image"
}

variable "clientWorkloadImageRegistryPassword" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Registry password for client workload image"
}

# Custom Workload Configuration
variable "customWorkloadImageAddress" {
  type        = string
  default     = ""
  description = "Container image address for custom workload"
}

variable "customWorkloadPort" {
  type        = number
  default     = 8080
  description = "Port exposed by the custom workload container"
}

variable "customWorkloadCommand" {
  type        = string
  default     = ""
  description = "Command for custom workload container"
}

variable "customWorkloadArguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for custom workload container"
}

variable "customWorkloadEnvironmentVariables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Environment variables for custom workload container"
}

variable "customWorkloadImageRegistryLoginServer" {
  type        = string
  default     = ""
  description = "Registry login server for custom workload image"
}

variable "customWorkloadImageRegistryUsername" {
  type        = string
  default     = ""
  description = "Registry username for custom workload image"
}

variable "customWorkloadImageRegistryPassword" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Registry password for custom workload image"
}

# VLLM Workload Configuration
variable "vllmWorkloadHfToken" {
  type        = string
  default     = ""
  sensitive   = true
  description = "HuggingFace token for VLLM workload"
}

variable "vllmWorkloadVllmModel" {
  type        = string
  default     = ""
  description = "Model name for VLLM workload"
}

# Ollama Configuration
variable "ollamaModelName" {
  type        = string
  default     = "llama3.2:1b-instruct-q4_0"
  description = "Model name for Ollama"
}

# Compute Resources
variable "container_cpu" {
  type        = number
  default     = 1
  description = "CPU cores for main workload container"
}

variable "container_memory" {
  type        = number
  default     = 4
  description = "Memory size in GB for main workload container"
}

# Networking Configuration
variable "virtualNetworkNewOrExisting" {
  type        = string
  default     = "new"
  description = "Should a new virtual network be created (new) or use an existing one (existing)"
  validation {
    condition     = contains(["", "new", "existing"], var.virtualNetworkNewOrExisting)
    error_message = "The virtualNetworkNewOrExisting must be either 'password' or 'sshPublicKey'"
  }
}

variable "new_vnet_enabled" {
  type        = bool
  default     = true
  description = "Whether to create a new virtual network (true) or use an existing one (false)"
}

variable "networking_type" {
  type        = string
  default     = "Public"
  validation {
    condition     = contains(["Public", "Private"], var.networking_type)
    error_message = "The networking_type must be either 'Public' or 'Private'."
  }
  description = "Networking type for the container group (Public or Private)"
}

variable "dns_name_label" {
  type        = string
  default     = ""
  description = "DNS name label for public IP (leave empty for auto-generated name)"
}

variable "virtualNetworkName" {
  type        = string
  default     = "vNet"
  description = "Name of the virtual network"
}

variable "vnet_name" {
  type        = string
  default     = ""
  description = "Name of the existing virtual network when create_new_vnet=false"
}

variable "virtualNetworkResourceGroup" {
  type        = string
  default     = ""
  description = "Resource group containing the virtual network"
}

variable "vnet_resource_group" {
  type        = string
  default     = ""
  description = "Resource group containing the virtual network (for existing VNet, leave empty to use the module's resource group)"
}

variable "virtualNetworkAddressPrefixes" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address prefixes for the virtual network"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for a new virtual network"
}

variable "subnetName" {
  type        = string
  default     = "default"
  description = "Name of the subnet"
}

variable "subnet_name" {
  type        = string
  default     = "default"
  description = "Name of the subnet (either to be created or existing)"
}

variable "subnetAddressPrefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Address prefix for the subnet"
}

variable "subnet_address_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Address prefix for a new subnet"
}

# Key Vault Configuration
variable "keyVaultBaseDomain" {
  type        = string
  default     = "vault.azure.net"
  description = "The base domain for Key Vault"
}

variable "enable_key_vault" {
  type        = bool
  default     = true
  description = "Enable confidential computing with hardware-based attestation and secure key release"
}

# Polaris Proxy Configuration
variable "polarisProxyImageVersion" {
  type        = string
  default     = "latest"
  description = "Polaris proxy image version/tag"
}

variable "polaris_proxy_image_version" {
  type        = string
  default     = "latest"
  description = "Polaris proxy image version/tag"
}

variable "polarisProxyPort" {
  type        = number
  default     = 3000
  description = "Port exposed by the Polaris proxy container"
}

variable "polaris_proxy_port" {
  type        = number
  default     = 3000
  description = "Port exposed by the Polaris proxy container"
}

variable "polarisProxyEnableCORS" {
  type        = bool
  default     = false
  description = "Enable CORS for API endpoints"
}

variable "polaris_proxy_enable_cors" {
  type        = bool
  default     = false
  description = "Enable CORS for API endpoints"
}

variable "polarisProxyEnableInputEncryption" {
  type        = bool
  default     = false
  description = "Enable encryption for input data"
}

variable "polaris_proxy_enable_input_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for input data"
}

variable "polarisProxyEnableOutputEncryption" {
  type        = bool
  default     = false
  description = "Enable encryption for output data"
}

variable "polaris_proxy_enable_output_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for output data"
}

variable "polarisProxyEnableLogging" {
  type        = bool
  default     = true
  description = "Enable enhanced logging"
}

variable "polaris_proxy_enable_logging" {
  type        = bool
  default     = true
  description = "Enable enhanced logging"
}

variable "polaris_proxy_source_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "IP ranges allowed to access the Polaris proxy"
}

variable "workload_port" {
  type        = number
  default     = 8000
  description = "Port exposed by the workload container"
}

variable "workload_env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the workload container"
}

variable "workload_arguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for the workload container"
}

# Container Registry
variable "registry_login_server" {
  type        = string
  default     = ""
  description = "Custom container registry login server (if using)"
}

variable "registry_username" {
  type        = string
  default     = ""
  description = "Custom container registry username"
}

variable "registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Custom container registry password"
}