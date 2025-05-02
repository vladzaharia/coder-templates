terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    aws = {
      source  = "hashicorp/aws"
    }
    vault = {
      source  = "hashicorp/vault"
    }
  }
}

# Last updated 2023-03-14
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  description  = "The region to deploy the workspace in."
  default      = "us-west-2"
  mutable      = false
  option {
    name  = "Asia Pacific (Tokyo)"
    value = "ap-northeast-1"
    icon  = "/emojis/1f1ef-1f1f5.png"
  }
  option {
    name  = "Asia Pacific (Seoul)"
    value = "ap-northeast-2"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Asia Pacific (Osaka)"
    value = "ap-northeast-3"
    icon  = "/emojis/1f1ef-1f1f5.png"
  }
  option {
    name  = "Asia Pacific (Mumbai)"
    value = "ap-south-1"
    icon  = "/emojis/1f1ee-1f1f3.png"
  }
  option {
    name  = "Asia Pacific (Singapore)"
    value = "ap-southeast-1"
    icon  = "/emojis/1f1f8-1f1ec.png"
  }
  option {
    name  = "Asia Pacific (Sydney)"
    value = "ap-southeast-2"
    icon  = "/emojis/1f1e6-1f1fa.png"
  }
  option {
    name  = "Canada (Central)"
    value = "ca-central-1"
    icon  = "/emojis/1f1e8-1f1e6.png"
  }
  option {
    name  = "EU (Frankfurt)"
    value = "eu-central-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Stockholm)"
    value = "eu-north-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Ireland)"
    value = "eu-west-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (London)"
    value = "eu-west-2"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Paris)"
    value = "eu-west-3"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "South America (São Paulo)"
    value = "sa-east-1"
    icon  = "/emojis/1f1e7-1f1f7.png"
  }
  option {
    name  = "US East (N. Virginia)"
    value = "us-east-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US East (Ohio)"
    value = "us-east-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (N. California)"
    value = "us-west-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (Oregon)"
    value = "us-west-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "What instance type should your workspace use?"
  default      = "t3a.small"
  mutable      = false
  option {
    name  = "Micro (2c/1GB) - $0.0094/hr"
    value = "t3a.micro"
  }
  option {
    name  = "Small (2c/2GB) - $0.0188/hr"
    value = "t3a.small"
  }
  option {
    name  = "Medium (2c/4GB) - $0.0376/hr"
    value = "t3a.medium"
  }
  option {
    name  = "Large (2c/8GB) - $0.0752/hr"
    value = "t3a.large"
  }
  option {
    name  = "XLarge (4c/16GB) - $0.1504/hr"
    value = "t3a.xlarge"
  }
  option {
    name  = "2XLarge (8c/32GB) - $0.3328"
    value = "t3.2xlarge"
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

data "vault_aws_access_credentials" "client_info" {
  role    = "administrator"
  backend = "aws"
}

provider "aws" {
  region     = data.coder_parameter.region.value
  access_key = data.vault_aws_access_credentials.client_info.access_key
  secret_key = data.vault_aws_access_credentials.client_info.secret_key
}

data "coder_workspace" "main" {}
data "coder_workspace_owner" "me" {}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

resource "coder_agent" "main" {
  arch = "amd64"
  auth = "aws-instance-identity"
  os   = "windows"
}

locals {

  # User data is used to stop/start AWS instances. See:
  # https://github.com/hashicorp/terraform-provider-aws/issues/22

  availability_zone = "${data.coder_parameter.region.value}a"

  user_data_start = base64encode(
    templatefile("${path.module}/Initialize.ps1.tftpl", { init_script = coder_agent.main.init_script })
  )

  user_data_end = <<EOT
<powershell>
shutdown /s
</powershell>
<persist>true</persist>
EOT
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "coder_metadata" "private-key" {
  resource_id = tls_private_key.rsa.id
  item {
    key   = "algorithm"
    value = tls_private_key.rsa.algorithm
  }

  item {
    key   = "bit size"
    value = tls_private_key.rsa.rsa_bits
  }
}

resource "aws_key_pair" "dev" {
  key_name   = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "coder_metadata" "key-pair" {
  resource_id = aws_key_pair.dev.id
  item {
    key   = "name"
    value = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-key-pair"
  }
}

resource "aws_vpc" "dev" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-vpc"
  }
}

resource "coder_metadata" "vpc" {
  resource_id = aws_vpc.dev.id
  item {
    key   = "name"
    value = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-vpc"
  }
  item {
    key   = "cidr block"
    value = aws_vpc.dev.cidr_block
  }
}

resource "aws_subnet" "dev" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = local.availability_zone

  tags = {
    Name = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-subnet"
  }
}

resource "coder_metadata" "subnet" {
  resource_id = aws_subnet.dev.id
  item {
    key   = "name"
    value = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-subnet"
  }
  item {
    key   = "cidr block"
    value = aws_subnet.dev.cidr_block
  }
}

# resource "aws_security_group" "allow_rdp" {
#   name        = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-allow-rdp"
#   description = "Allow RDP inbound traffic"
#   vpc_id      = aws_vpc.dev.id

#   ingress {
#     description = "RDP from VPC"
#     from_port   = 3389
#     to_port     = 3389
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.dev.cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_rdp"
#   }
# }

resource "aws_security_group" "allow_all" {
  name        = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}-allow-all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.dev.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_rdp"
  }
}

resource "aws_instance" "dev" {
  ami                         = data.aws_ami.windows.id
  availability_zone           = local.availability_zone
  instance_type               = data.coder_parameter.instance_type.value
  subnet_id                   = aws_subnet.dev.id
  associate_public_ip_address = true

  key_name = aws_key_pair.dev.key_name

  user_data = data.coder_workspace.me.transition == "start" ? local.user_data_start : local.user_data_end

  get_password_data = true
  connection {
    host     = self.public_ip
    type     = "winrm"
    port     = 5986
    password = rsadecrypt(self.password_data, tls_private_key.rsa.private_key_pem)
    https    = true
    insecure = true
  }

  tags = {
    Name = "coder-${data.coder_workspace_owner.me.owner.name}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
}

resource "coder_app" "rdp" {
  agent_id     = coder_agent.main.id
  slug         = "rdp"
  display_name = "Remote Desktop"
  icon         = "https://yoolk.ninja/wp-content/uploads/2020/06/Apps-Ms-Remote-Desktop-1024x1024.png"
  url          = "rdp://${aws_instance.dev.public_ip}:3389&username=s:Administrator"
  external     = true
}

resource "coder_metadata" "workspace_info" {
  resource_id = aws_instance.dev.id
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key   = "instance type"
    value = aws_instance.dev.instance_type
  }
  item {
    key   = "disk"
    value = "${aws_instance.dev.root_block_device[0].volume_size} GiB"
  }
  item {
    key   = "username"
    value = "Administrator"
  }
  item {
    key       = "password"
    value     = rsadecrypt(aws_instance.dev.password_data, tls_private_key.rsa.private_key_pem)
    sensitive = true
  }
  item {
    key   = "public ip"
    value = aws_instance.dev.public_ip
  }
}
