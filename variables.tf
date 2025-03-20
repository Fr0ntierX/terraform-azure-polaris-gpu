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


# Custom Workload Configuration
variable "custom_workload" {
  type = object({
    image_address         = string
    port                  = number
    command               = optional(string, "")  
    arguments             = optional(list(string), []) 
    environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    registry              = optional(object({  
      login_server = string
      username     = string
      password     = string
    }), null)
  })
  description = "Configuration for custom workload"
}

# VLLM Workload Configuration
variable "vllm_workload" {
  type = object({
    hf_token  = string
    vllm_model = string
  })
  default = {
    hf_token  = ""
    vllm_model = ""
  }
  description = "Configuration for VLLM workload"
}

# Ollama Workload Configuration
variable "ollama_workload" {
  type = object({
    model_name = string
  })
  default = {
    model_name = "llama3.2:1b-instruct-q4_0"
  }
  description = "Configuration for Ollama workload"
}

# TorchServe Workload Configuration
variable "torch_serve_workload" {
  type = object({
    model_archive_url = string
  })
  default = {
    model_archive_url = ""
  }
  description = "Configuration for TorchServe workload"
}

# Client Workload Configuration
variable "client_workload" {
  type = object({
    image_address         = string
    port                  = number
    command               = optional(string, "") 
    arguments             = optional(list(string), [])
    environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    registry              = optional(object({ 
      login_server = string
      username     = string
      password     = string
    }), null)
  })
  default = {
    image_address         = ""
    port                  = 8080
    command               = ""
    arguments             = []
    environment_variables = []
    registry              = null
  }
  description = "Configuration for an optional client workload that interacts with the main workload"
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

# Networking Configuration - Only using existing VNets
variable "virtual_network_name" {
  type        = string
  description = "Name of the existing virtual network to use"
}

variable "virtual_network_resource_group" {
  type        = string
  description = "Resource group containing the existing virtual network (must be provided)"
}

variable "subnet_name" {
  type        = string
  description = "Name of the existing subnet within the virtual network"
}

# Key Vault Configuration
variable "key_vault_base_domain" {
  type        = string
  default     = "vault.azure.net"
  description = "The base domain for Key Vault"
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
