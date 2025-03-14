locals {
  workload_settings = {
    customWorkload = {
      name            = "workload"
      image           = var.customWorkloadImageAddress
      port            = var.customWorkloadPort
      url_for_proxy   = "workload:${var.customWorkloadPort}"
      extra_args      = join(" ", [for env in var.customWorkloadEnvironmentVariables : "-e ${env.name}=${env.value}"])
      command         = trimspace("${var.customWorkloadCommand} ${join(" ", var.customWorkloadArguments)}")
      container_image = var.customWorkloadImageAddress
    }
    vllmWorkload = {
      name            = "vllm-workload"
      port            = "8000"
      url_for_proxy   = "vllm-workload:8000"
      extra_args      = "-e HF_TOKEN=${var.vllmWorkloadHfToken} -e POLARIS_VLLM_MODEL=${var.vllmWorkloadVllmModel}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-llm-gpu-vllm:latest"
      command         = ""
    }
    ollamaWorkload = {
      name            = "ollama"
      port            = "11434"
      url_for_proxy   = "ollama:11434"
      extra_args      = "-e POLARIS_LLM_OLLAMA_MODEL=${var.ollamaModelName}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-llm-gpu-ollama:latest"
      command         = ""
    }
    torchServeWorkload = {
      name            = "workload"
      port            = "8080"
      url_for_proxy   = "workload:8080"
      extra_args      = "-e POLARIS_AI_MAR_FILE_URL=${var.modelArchiveUrl}"
      container_image = "fr0ntierxpublic.azurecr.io/polaris-ai-gpu-torchserve:latest"
      command         = ""
    #   gpus_required   = true
    }
  }

  selected_workload = lookup(local.workload_settings, var.workloadType, local.workload_settings.customWorkload)

  proxy_workload_url = var.clientWorkloadImageAddress == "" ? local.selected_workload.url_for_proxy : "client-workload:${var.clientWorkloadPort}"

  cloud_init_parts = {
    login = join("\n", [
      "docker login ${var.customWorkloadImageRegistryLoginServer} --username ${var.customWorkloadImageRegistryUsername} --password ${var.customWorkloadImageRegistryPassword}",
      var.clientWorkloadImageAddress != "" ? "docker login ${var.clientWorkloadImageRegistryLoginServer} --username ${var.clientWorkloadImageRegistryUsername} --password ${var.clientWorkloadImageRegistryPassword}" : ""
    ])

    setup = join("\n", [
      "docker network create secure-network",
      "docker pull fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polarisProxyImageVersion, "@sha256") ? var.polarisProxyImageVersion : ":${var.polarisProxyImageVersion}"}",
      "docker pull ${local.selected_workload.container_image}",
      var.clientWorkloadImageAddress != "" ? "docker pull ${var.clientWorkloadImageAddress}" : "",
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
        -p ${var.polarisProxyPort}:${var.polarisProxyPort} \
        -e POLARIS_CONTAINER_ENABLE_INPUT_ENCRYPTION=${lower(tostring(var.polarisProxyEnableInputEncryption))} \
        -e POLARIS_CONTAINER_ENABLE_OUTPUT_ENCRYPTION=${lower(tostring(var.polarisProxyEnableOutputEncryption))} \
        -e POLARIS_CONTAINER_ENABLE_CORS=${lower(tostring(var.polarisProxyEnableCORS))} \
        -e POLARIS_CONTAINER_ENABLE_LOGGING=${lower(tostring(var.polarisProxyEnableLogging))} \
        -e POLARIS_CONTAINER_AZURE_SKR_MAA_ENDPOINT=https://sharedweu.weu.attest.azure.net \
        -e POLARIS_CONTAINER_AZURE_SKR_AKV_ENDPOINT=https://${lower(local.key_vault_name)}.${var.keyVaultBaseDomain} \
        -e POLARIS_CONTAINER_AZURE_SKR_KEY_RELEASE_ENDPOINT=http://polaris-azure-skr:8081 \
        -e POLARIS_CONTAINER_KEY_TYPE=azure-skr \
        -e POLARIS_CONTAINER_AZURE_SKR_KID=${local.key_name} \
        -e POLARIS_CONTAINER_WORKLOAD_BASE_URL=http://${local.proxy_workload_url} \
        fr0ntierxpublic.azurecr.io/polaris-proxy${startswith(var.polarisProxyImageVersion, "@sha256") ? var.polarisProxyImageVersion : ":${var.polarisProxyImageVersion}"}
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

    run_client = var.clientWorkloadImageAddress != "" ? format(
      "docker run -d --network secure-network --name client-workload -p %s:%s %s %s %s %s",
      var.clientWorkloadPort,
      var.clientWorkloadPort,
      join(" ", [for env in var.clientWorkloadEnvironmentVariables : "-e ${env.name}=${env.value}"]),
      var.clientWorkloadImageAddress,
      var.clientWorkloadCommand,
      join(" ", var.clientWorkloadArguments)
    ) : ""
  }

  cloud_init_commands = compact(flatten([
    split("\n", local.cloud_init_parts.login),
    split("\n", local.cloud_init_parts.setup),
    split("\n", local.cloud_init_parts.run_skr),
    split("\n", local.cloud_init_parts.run_proxy),
    split("\n", local.cloud_init_parts.run_workload),
    var.clientWorkloadImageAddress != "" ? split("\n", local.cloud_init_parts.run_client) : []
  ]))

  cloud_init_script = <<-EOT
    #cloud-config
    runcmd:
    ${join("\n", [for cmd in local.cloud_init_commands : "      - ${trimspace(replace(cmd, "/\\s+/", " "))}"])}
  EOT
}
