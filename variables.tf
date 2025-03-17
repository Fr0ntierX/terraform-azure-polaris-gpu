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
variable "admin_username" {
  type        = string
  description = "User name for the Virtual Machine"
}

variable "admin_password_or_key" {
  type        = string
  sensitive   = true
  description = "Password or SSH key for the Virtual Machine"
}

variable "authentication_type" {
  type        = string
  default     = "sshPublicKey"
  description = "Type of authentication to use on the Virtual Machine"
  validation {
    condition     = contains(["password", "sshPublicKey"], var.authentication_type)
    error_message = "The authentication_type must be either 'password' or 'sshPublicKey'"
  }
}

variable "zone" {
  type        = string
  default     = "1"
  description = "Zone for the VM"
}

variable "vm_size" {
  type        = string
  default     = "Standard_NCC40ads_H100_v5"
  description = "The size of the VM"
}

# Workload Types
variable "workload_type" {
  type        = string
  description = "Type of workload to run (customWorkload, vllmWorkload, ollamaWorkload, or torchServeWorkload)"
  validation {
    condition     = contains(["customWorkload", "vllmWorkload", "ollamaWorkload", "torchServeWorkload"], var.workload_type)
    error_message = "The workload_type must be one of: customWorkload, vllmWorkload, ollamaWorkload, torchServeWorkload"
  }
}

# Client Workload Configuration
variable "client_workload_image_address" {
  type        = string
  default     = ""
  description = "Container image address for client workload"
}

variable "client_workload_port" {
  type        = number
  default     = 8080
  description = "Port exposed by the client workload container"
}

variable "client_workload_command" {
  type        = string
  default     = ""
  description = "Command for client workload container"
}

variable "client_workload_arguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for client workload container"
}

variable "client_workload_environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Environment variables for client workload container"
}

variable "client_workload_image_registry_login_server" {
  type        = string
  default     = ""
  description = "Registry login server for client workload image"
}

variable "client_workload_image_registry_username" {
  type        = string
  default     = ""
  description = "Registry username for client workload image"
}

variable "client_workload_image_registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Registry password for client workload image"
}

# Custom Workload Configuration
variable "custom_workload_image_address" {
  type        = string
  default     = ""
  description = "Container image address for custom workload"
}

variable "custom_workload_port" {
  type        = number
  default     = 8080
  description = "Port exposed by the custom workload container"
}

variable "custom_workload_command" {
  type        = string
  default     = ""
  description = "Command for custom workload container"
}

variable "custom_workload_arguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for custom workload container"
}

variable "custom_workload_environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Environment variables for custom workload container"
}

variable "custom_workload_image_registry_login_server" {
  type        = string
  default     = ""
  description = "Registry login server for custom workload image"
}

variable "custom_workload_image_registry_username" {
  type        = string
  default     = ""
  description = "Registry username for custom workload image"
}

variable "custom_workload_image_registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Registry password for custom workload image"
}

# VLLM Workload Configuration
variable "vllm_workload_hf_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "HuggingFace token for VLLM workload"
}

variable "vllm_workload_vllm_model" {
  type        = string
  default     = ""
  description = "Model name for VLLM workload"
}

# Ollama Configuration
variable "ollama_model_name" {
  type        = string
  default     = "llama3.2:1b-instruct-q4_0"
  description = "Model name for Ollama"
}

variable "model_archive_url" {
  type        = string
  default     = ""
  description = "URL for the model archive"
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
variable "virtual_network_new_or_existing" {
  type        = string
  default     = "new"
  description = "Should a new virtual network be created (new) or use an existing one (existing)"
  validation {
    condition     = contains(["", "new", "existing"], var.virtual_network_new_or_existing)
    error_message = "The virtual_network_new_or_existing must be either '', 'new', or 'existing'"
  }
}

variable "new_vnet_enabled" {
  type        = bool
  default     = true
  description = "Whether to create a new virtual network (true) or use an existing one (false)"
}

variable "networking_type" {
  type    = string
  default = "Public"
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

variable "virtual_network_name" {
  type        = string
  default     = "vNet"
  description = "Name of the virtual network"
}

variable "vnet_name" {
  type        = string
  default     = ""
  description = "Name of the existing virtual network when create_new_vnet=false"
}

variable "virtual_network_resource_group" {
  type        = string
  default     = ""
  description = "Resource group containing the virtual network"
}

variable "vnet_resource_group" {
  type        = string
  default     = ""
  description = "Resource group containing the virtual network (for existing VNet, leave empty to use the module's resource group)"
}

variable "virtual_network_address_prefixes" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address prefixes for the virtual network"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for a new virtual network"
}

variable "subnet_name" {
  type        = string
  default     = "default"
  description = "Name of the subnet"
}

variable "subnet_address_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Address prefix for the subnet"
}

# Key Vault Configuration
variable "key_vault_base_domain" {
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
variable "polaris_proxy_image_version" {
  type        = string
  default     = "latest"
  description = "Polaris proxy image version/tag"
}

variable "polaris_proxy_port" {
  type        = number
  default     = 3000
  description = "Port exposed by the Polaris proxy container"
}

variable "polaris_proxy_enable_cors" {
  type        = bool
  default     = false
  description = "Enable CORS for API endpoints"
}


variable "maa_endpoint" {
  type        = string
  default     = ""
  description = "URL for the Microsoft Attestation service"
}

variable "polaris_proxy_enable_input_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for input data"
}

variable "polaris_proxy_enable_output_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for output data"
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
