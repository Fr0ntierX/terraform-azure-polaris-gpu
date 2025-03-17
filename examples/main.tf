module "polaris_azure_gpu_module" {
  source = "../"

  subscription_id = "3bc57494-c0a6-4ee2-b44d-8b398b4a8162"

  name     = "polaris-gpu-example"
  location = "eastus2"
  zone     = "2"

  # VM Configuration
  admin_username        = "azureuser"
  authentication_type   = "password"
  admin_password_or_key = "YOUR_PASSWORD"

  # Polaris Proxy Configuration
  polaris_proxy_port          = 3000
  polaris_proxy_image_version = "latest"

  # Workload Configuration
  workload_type = "customWorkload"

  custom_workload_image_address = "YOUR_ACR_SERVER/your-llm-image:latest"
  custom_workload_port          = 11434

  custom_workload_image_registry_login_server = "YOUR_ACR_SERVER"
  custom_workload_image_registry_username     = "YOUR_ACR_USERNAME"
  custom_workload_image_registry_password     = "YOUR_ACR_PASSWORD"
}
