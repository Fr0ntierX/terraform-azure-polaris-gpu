locals {
  workload_settings = {
    customWorkload = {
      name            = "workload"
      port            = var.custom_workload.port
      url_for_proxy   = "workload:${var.custom_workload.port}"
      extra_args      = join(" ", [for env in var.custom_workload.environment_variables : "-e ${env.name}=${env.value}"])
      container_image = var.custom_workload.image_address
      command         = trimspace("${var.custom_workload.command} ${join(" ", var.custom_workload.arguments)}")
    }
    vllmWorkload = {
      name            = "vllm-workload"
      port            = "8000"
      url_for_proxy   = "vllm-workload:8000"
      extra_args      = "-e HF_TOKEN=${var.vllm_workload.hf_token} -e POLARIS_VLLM_MODEL=${var.vllm_workload.vllm_model}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-llm-gpu-vllm:latest"
      command         = "" 
    }
    ollamaWorkload = {
      name            = "ollama"
      port            = "11434"
      url_for_proxy   = "ollama:11434"
      extra_args      = "-e POLARIS_LLM_OLLAMA_MODEL=${var.ollama_workload.model_name}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-llm-gpu-ollama:latest"
      command         = ""
    }
    torchServeWorkload = {
      name            = "workload"
      port            = "8080"
      url_for_proxy   = "workload:8080"
      extra_args      = "-e POLARIS_AI_MAR_FILE_URL=${var.torch_serve_workload.model_archive_url}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-ai-gpu-torchserve:latest"
      command         = ""
    }
  }

  has_custom_workload      = var.custom_workload.image_address != ""
  has_vllm_workload        = var.vllm_workload.vllm_model != "" 
  has_ollama_workload      = var.ollama_workload.model_name != "llama3.2:1b-instruct-q4_0"
  has_torch_serve_workload = var.torch_serve_workload.model_archive_url != ""

  workload_count = (
    (local.has_custom_workload ? 1 : 0) +
    (local.has_vllm_workload ? 1 : 0) +
    (local.has_ollama_workload ? 1 : 0) +
    (local.has_torch_serve_workload ? 1 : 0)
  )

  workload_validation = local.workload_count <= 1 ? true : tobool(
    file("ERROR: Multiple workload configurations detected. Please specify only one workload type.")
  )

  detected_workload_type = (
    local.has_custom_workload ? "customWorkload" : (
      local.has_vllm_workload ? "vllmWorkload" : (
        local.has_ollama_workload ? "ollamaWorkload" : (
          local.has_torch_serve_workload ? "torchServeWorkload" :
          "customWorkload"
    )))
  )

  selected_workload = local.workload_validation ? local.workload_settings[local.detected_workload_type] : null

  proxy_workload_url = local.selected_workload.url_for_proxy

  cloud_init_parts = {
    login = join("\n", [
      "docker login ${var.custom_workload.registry.login_server} --username ${var.custom_workload.registry.username} --password ${var.custom_workload.registry.password}",
      var.client_workload.image_address != "" ? "docker login ${var.client_workload.registry.login_server} --username ${var.client_workload.registry.username} --password ${var.client_workload.registry.password}" : ""
    ])

    setup = join("\n", [
      "docker network create secure-network",
      "docker pull fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polaris_proxy_image_version, "@sha256") ? var.polaris_proxy_image_version : ":${var.polaris_proxy_image_version}"}",
      "docker pull ${local.selected_workload.container_image}",
      var.client_workload.image_address != "" ? "docker pull ${var.client_workload.image_address}" : "",
      "docker pull fr0ntierxpublic.azurecr.io/polaris-azure-skr:latest"
    ])

    run_skr = <<-EOT
      docker run -p 8081:8081 -d \
        -e PORT=8081 \
        --privileged \
        --network secure-network \
        --volume=/dev/tpmrm0:/dev/tpmrm0 \
        --volume=/sys/kernel/security:/sys/kernel/security \
        --name polaris-azure-skr \
        fr0ntierxpublic.azurecr.io/polaris-azure-skr:latest
    EOT

    run_proxy = <<-EOT
      docker run -d \
        --network secure-network \
        --name polaris-secure-proxy \
        -p ${var.polaris_proxy_port}:${var.polaris_proxy_port} \
        -e POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION=${lower(tostring(var.polaris_proxy_enable_input_encryption))} \
        -e POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION=${lower(tostring(var.polaris_proxy_enable_output_encryption))} \
        -e POLARIS_CONTAINER_ENABLE_CORS=${lower(tostring(var.polaris_proxy_enable_cors))} \
        -e POLARIS_CONTAINER_ENABLE_LOGGING=${lower(tostring(var.polaris_proxy_enable_logging))} \
        -e POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT=https://${var.maa_endpoint} \
        -e POLARIS_CONTAINER_AZURE_SKR_AKV_ENDPOINT=https://${lower(local.key_vault_name)}.${var.key_vault_base_domain} \
        -e POLARIS_CONTAINER_AZURE_SKR_KEY_RELEASE_ENDPOINT=http://polaris-azure-skr:8081 \
        -e POLARIS_CONTAINER_KEY_TYPE=azure-skr \
        -e POLARIS_CONTAINER_AZURE_SKR_KID=${local.key_name} \
        -e POLARIS_CONTAINER_WORKLOAD_BASE_URL=http://${local.proxy_workload_url} \
        fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polaris_proxy_image_version, "@sha256") ? var.polaris_proxy_image_version : ":${var.polaris_proxy_image_version}"}
    EOT

    run_workload = <<-EOT
      docker run -d \
        --network secure-network \
        --name ${local.selected_workload.name} \
        -p ${local.selected_workload.port}:${local.selected_workload.port} \
        ${local.selected_workload.extra_args} \
        --restart=always -it --gpus all \
        ${local.selected_workload.container_image} \
        ${local.selected_workload.command}
    EOT

    run_client = var.client_workload.image_address != "" ? format(
      "docker run -d --network secure-network --name client-workload -p %s:%s %s %s %s %s\n",
      var.client_workload.port,
      var.client_workload.port,
      join(" ", [for env in var.client_workload.environment_variables : "-e ${env.name}=${env.value}"]),
      var.client_workload.image_address,
      var.client_workload.command,
      join(" ", var.client_workload.arguments)
    ) : ""
  }

  cloud_init_commands = compact(flatten([
    split("\n", local.cloud_init_parts.login),
    split("\n", local.cloud_init_parts.setup),
    split("\n", local.cloud_init_parts.run_skr),
    split("\n", local.cloud_init_parts.run_proxy),
    split("\n", local.cloud_init_parts.run_workload),
    var.client_workload.image_address != "" ? split("\n", local.cloud_init_parts.run_client) : []
  ]))

  cloud_init_script = <<-EOT
    #cloud-config
    runcmd:
    ${join("\n", [for cmd in local.cloud_init_commands : "      - ${trimspace(replace(cmd, "/\\s+/", " "))}"])}
  EOT
}