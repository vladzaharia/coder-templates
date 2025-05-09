terraform {
  required_providers {
    coder = {
      source = "coder/coder"

    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    vault = {
      source = "hashicorp/vault"
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

provider "coder" {}
data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

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

data "coder_parameter" "data_disk_size" {
  description  = "Size of your data (F:) drive in GB"
  display_name = "Data disk size"
  name         = "data_disk_size"
  default      = 8
  mutable      = "false"
  type         = "number"
  validation {
    min = 1
    max = 128
  }
}

resource "coder_agent" "main" {
  arch = "amd64"
  auth = "azure-instance-identity"
  os   = "windows"
}

resource "random_password" "admin_password" {
  length  = 16
  special = true
  # https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements#reference
  # we remove characters that require special handling in XML, as this is how we pass it to the VM
  # namely: <>&'"
  override_special = "~!@#$%^*_-+=`|\\(){}[]:;,.?/"
}

locals {
  prefix         = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.main.name}"
  admin_username = data.coder_workspace_owner.me.name
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = data.coder_parameter.location.value
  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${local.prefix}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
  }
}
resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
  }
}
resource "azurerm_subnet" "internal" {
  name                 = "${local.prefix}-subnet"
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
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
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
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
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

resource "azurerm_managed_disk" "data_disk" {
  name                 = "${local.prefix}-data"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = data.coder_parameter.data_disk_size.value

  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
  }
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "main" {
  count                 = data.coder_workspace.main.transition == "start" ? 1 : 0
  name                  = "${local.prefix}-vm"
  computer_name         = "coder-vm"
  admin_username        = local.admin_username
  admin_password        = random_password.admin_password.result
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = data.coder_parameter.instance_type.value
  custom_data = base64encode(
    templatefile("${path.module}/Initialize.ps1.tftpl", { init_script = coder_agent.main.init_script })
  )
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  additional_unattend_content {
    content = "<AutoLogon><Password><Value>${random_password.admin_password.result}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${local.admin_username}</Username></AutoLogon>"
    setting = "AutoLogon"
  }
  additional_unattend_content {
    content = file("${path.module}/FirstLogonCommands.xml")
    setting = "FirstLogonCommands"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
  tags = {
    Coder_Provisioned = "true"
    Workspace         = data.coder_workspace.main.id
    Owner             = data.coder_workspace_owner.me.name
  }
}

resource "coder_app" "rdp" {
  agent_id     = coder_agent.main.id
  slug         = "rdp"
  display_name = "Remote Desktop"
  icon         = "https://yoolk.ninja/wp-content/uploads/2020/06/Apps-Ms-Remote-Desktop-1024x1024.png"
  url          = "rdp://${azurerm_public_ip.main.ip_address}:3389&username=s:${local.admin_username}"
  external     = true
}

resource "coder_metadata" "rdp" {
  count       = data.coder_workspace.main.transition == "start" ? 1 : 0
  resource_id = azurerm_windows_virtual_machine.main[0].id
  item {
    key   = "region"
    value = data.coder_parameter.location.value
  }
  item {
    key   = "instance type"
    value = data.coder_parameter.instance_type.value
  }
  item {
    key   = "username"
    value = local.admin_username
  }
  item {
    key       = "password"
    value     = random_password.admin_password.result
    sensitive = true
  }
}

resource "coder_metadata" "data_info" {
  resource_id = azurerm_managed_disk.data_disk.id

  item {
    key   = "size"
    value = "${data.coder_parameter.data_disk_size.value} GiB"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main_data" {
  count              = data.coder_workspace.main.transition == "start" ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.main[0].id
  lun                = "10"
  caching            = "ReadWrite"
}
