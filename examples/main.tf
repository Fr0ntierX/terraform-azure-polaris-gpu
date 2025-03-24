module "polaris_azure_gpu_module" {
  source = "Fr0ntierX/polaris/azure-gpu"

  subscription_id = "your-subscription-id"

  # Core configuration
  name     = "polaris-gpu-example"
  location = "eastus2"
  zone     = "2"

  # VM Configuration
  admin_username        = "azureuser"
  authentication_type   = "password"
  admin_password_or_key = "YOUR_PASSWORD"

  # Network Configuration
  virtual_network_name           = "your-network-vnet"
  virtual_network_resource_group = "your-network-rg"
  subnet_name                    = "default"

  custom_workload = {
    image_address = "example.azurecr.io/custom-workload:latest"
    port          = 11434
    registry = {
      login_server = "YOUR_ACR_SERVER"
      username     =  "YOUR_ACR_USERNAME"
      password     = "YOUR_ACR_PASSWORD"
    }
  }

  client_workload = {
    image_address = "example.azurecr.io/client:latest"
    port          = 8080
    registry = {
      login_server = "YOUR_ACR_SERVER"
      username     =  "YOUR_ACR_USERNAME"
      password     = "YOUR_ACR_PASSWORD"
    }
  }

  # Polaris proxy configuration
  polaris_proxy_image_version = "latest"
}