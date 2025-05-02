terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
    }
    vault = {
      source  = "hashicorp/vault"
    }
  }
}

variable "vault_role_id" {
  type        = string
  description = "Role ID for Vault lookup"

  validation {
    condition     = length(var.vault_role_id) == 36
    error_message = "Invalid Vault Role ID."
  }
}

variable "vault_secret_id" {
  type        = string
  description = "Secret ID for Vault lookup"
  sensitive   = true

  validation {
    condition     = length(var.vault_secret_id) == 36
    error_message = "Invalid Vault Secret ID."
  }
}

provider "vault" {
  address          = "https://vault.polaris.rest"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

locals {
  tenant_id       = "cbaca1db-904b-4586-a844-74be35525d81"
  subscription_id = "a2470d3d-f20a-4263-b5d7-a424da9d52d9"
}

data "vault_azure_access_credentials" "client_info" {
  role                        = "subscription-owner"
  backend                     = "azure"
  environment                 = "AzurePublicCloud"
  tenant_id                   = local.tenant_id
  subscription_id             = local.subscription_id
  validate_creds              = true
  num_sequential_successes    = 8
  num_seconds_between_tests   = 1
  max_cred_validation_seconds = 300
}

provider "azurerm" {
  features {}

  client_id       = data.vault_azure_access_credentials.client_info.client_id
  client_secret   = data.vault_azure_access_credentials.client_info.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.subscription_id
}

provider "coder" {
}

data "coder_parameter" "location" {
  name         = "location"
  display_name = "Location"
  description  = "What location should your workspace live in?"
  default      = "westus2"
  icon         = "/emojis/1f310.png"
  mutable      = false
  option {
    name  = "CentralUS - Iowa"
    value = "centralus"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "EastUS - Virginia"
    value = "eastus"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "EastUS2 - Virginia"
    value = "eastus2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "SouthCentralUS - Texas"
    value = "southcentralus"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "WestUS - Wyoming"
    value = "westus"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "WestUS2 - Washington"
    value = "westus2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "WestUS3 - Arizona"
    value = "westus3"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "CanadaCentral - Toronto"
    value = "canadacentral"
    icon  = "/emojis/1f1e8-1f1e6.png"
  }
  option {
    name  = "SouthEastAsia - Singapore"
    value = "southeastasia"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "NorthEurope - Ireland"
    value = "northeurope"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "WestEurope - Netherlands"
    value = "westeurope"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "SouthAfricaNorth - Johannesburg"
    value = "southafricanorth"
    icon  = "/emojis/1f1ff-1f1e6.png"
  }
  option {
    name  = "UKSouth - London"
    value = "uksouth"
    icon  = "/emojis/1f1ec-1f1e7.png"
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "What instance type should your workspace use?"
  default      = "Standard_B2ms"
  icon         = "/icon/azure.png"
  mutable      = false
  option {
    name  = "Standard_B1s (1c/1GB) - $0.014/hr"
    value = "Standard_B1s"
  }
  option {
    name  = "Standard_B1ms (1c/2GB) - $0.0207/hr"
    value = "Standard_B1ms"
  }
  option {
    name  = "Standard_B2s (2c/4GB) - $0.0416/hr"
    value = "Standard_B2s"
  }
  option {
    name  = "Standard_B2ms (2c/8GB) - $0.0832/hr"
    value = "Standard_B2ms"
  }
  option {
    name  = "Standard_B4ms (4c/16GB) - $0.166/hr"
    value = "Standard_B4ms"
  }
  option {
    name  = "Standard_B8ms (8c/32GB) - $0.333/hr"
    value = "Standard_B8ms"
  }
  option {
    name  = "Standard_D2ls_v5 (2c/4GB) - $0.085/hr"
    value = "Standard_D2ls_v5"
  }
  option {
    name  = "Standard_D4ls_v5 (4c/8GB) - $0.17/hr"
    value = "Standard_D4ls_v5"
  }
  option {
    name  = "Standard_D8as_v5 (8c/16GB) - $0.34/hr"
    value = "Standard_D8ls_v5"
  }
  option {
    name  = "Standard_D16as_v5 (16c/32GB) - $0.68/hr"
    value = "Standard_D16ls_v5"
  }
  option {
    name  = "Standard_D32as_v5 (32c/64GB) - $1.36/hr"
    value = "Standard_D32ls_v5"
  }
}

data "coder_parameter" "home_size" {
  name         = "home_size"
  display_name = "Home volume size"
  description  = "How large would you like your home volume to be (in GB)?"
  default      = 8
  type         = "number"
  icon         = "/icon/azure.png"
  mutable      = false
  validation {
    min = 1
    max = 128
  }
}

data "coder_parameter" "dotfiles_repo" {
  order        = 150
  name         = "dotfiles_repo"
  display_name = "Dotfiles repo"
  description  = "GitHub repository to download and install dotfiles, if provided."
  icon         = "https://static-00.iconduck.com/assets.00/github-icon-512x497-oppthre2.png"
  default      = ""
  mutable      = false
}


data "coder_workspace" "me" {
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  auth = "azure-instance-identity"

  startup_script = <<-EOT
    #!/bin/bash
    set -e
    if [ -n "$DOTFILES_URI" ]; then
      echo "Installing dotfiles from $DOTFILES_URI"
      coder dotfiles -y "https://github.com/$DOTFILES_URI"
    fi
  EOT

  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace_owner.me.owner.name}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace_owner.me.owner.name}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.owner.name_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.owner.name_email}"
    DOTFILES_URI        = data.coder_parameter.dotfiles_repo.value != "" ? data.coder_parameter.dotfiles_repo.value : null
    CODER_ENV           = "true"
  }

  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = <<-EOT
      #!/bin/bash
      set -e
      top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
    EOT
  }
  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = <<-EOT
      #!/bin/bash
      set -e
      free -m | awk 'NR==2{printf "%.2f%%\t", $3*100/$2 }'
    EOT
  }
  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/${data.coder_workspace_owner.me.owner.name} | awk '$NF=="/"{printf "%s", $5}'
    EOT
  }
}

locals {
  prefix = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}"

  userdata = templatefile("cloud-config.yaml.tftpl", {
    username    = data.coder_workspace_owner.me.owner.name
    init_script = base64encode(coder_agent.main.init_script)
    hostname    = lower(data.coder_workspace.me.name)
  })
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = data.coder_parameter.location.value

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${local.prefix}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${local.prefix}-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/29"]
}

resource "azurerm_network_interface" "main" {
  name                = "${local.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "boot_diagnostics" {
  name                     = "diag${random_id.storage_id.hex}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}
# Generate random text for a unique storage account name
resource "random_id" "storage_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.main.name
  }
  byte_length = 8
}

resource "azurerm_managed_disk" "home" {
  create_option        = "Empty"
  location             = azurerm_resource_group.main.location
  name                 = "${local.prefix}-home"
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "StandardSSD_LRS"
  disk_size_gb         = data.coder_parameter.home_size.value

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}

// azurerm requires an SSH key (or password) for an admin user or it won't start a VM.  However,
// cloud-init overwrites this anyway, so we'll just use a dummy SSH key.
resource "tls_private_key" "dummy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "main" {
  count               = data.coder_workspace.me.transition == "start" ? 1 : 0
  name                = "${local.prefix}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = data.coder_parameter.instance_type.value
  // cloud-init overwrites this, so the value here doesn't matter
  admin_username = data.coder_workspace_owner.me.owner.name
  admin_ssh_key {
    public_key = tls_private_key.dummy.public_key_openssh
    username   = data.coder_workspace_owner.me.owner.name
  }

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  computer_name = lower(data.coder_workspace.me.name)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  user_data = base64encode(local.userdata)

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.me.id
    Owner             = data.coder_workspace_owner.me.owner.name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "home" {
  count              = data.coder_workspace.me.transition == "start" ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.home.id
  virtual_machine_id = azurerm_linux_virtual_machine.main[0].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = azurerm_linux_virtual_machine.main[0].id

  item {
    key   = "region"
    value = data.coder_parameter.location.value
  }
  item {
    key   = "instance type"
    value = azurerm_linux_virtual_machine.main[0].size
  }
  item {
    key   = "username"
    value = data.coder_workspace_owner.me.owner.name
  }
}

resource "coder_metadata" "home_info" {
  resource_id = azurerm_managed_disk.home.id

  item {
    key   = "size"
    value = "${data.coder_parameter.home_size.value} GiB"
  }
}
