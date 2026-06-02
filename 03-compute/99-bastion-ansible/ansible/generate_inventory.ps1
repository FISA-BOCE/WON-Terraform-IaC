$ErrorActionPreference = "Stop"

$ComputeTfDir = ".."
$NetworkTfDir = "..\..\..\01-network"

function Get-TerraformMapValue {
    param(
        [string]$OutputName,
        [string]$Key
    )

    $json = terraform "-chdir=$ComputeTfDir" output -json $OutputName
    $map = $json | ConvertFrom-Json
    return $map.$Key
}

function Resolve-PrivateKeyPath {
    param([string]$PrivateKeyFile)

    if ([System.IO.Path]::IsPathRooted($PrivateKeyFile)) {
        return $PrivateKeyFile
    }

    $normalized = $PrivateKeyFile -replace "^[./\\]+", ""
    return [System.IO.Path]::GetFullPath((Join-Path $NetworkTfDir $normalized))
}

$privateKeyFile = terraform "-chdir=$NetworkTfDir" output -raw boce_private_key_file
$privateKeyFile = Resolve-PrivateKeyPath $privateKeyFile

$hosts = @{
    "card_ansible_bastion" = @{
        "ansible_host" = Get-TerraformMapValue "ansible_bastion_public_ips" "card-ansible-bastion-server"
        "private_ip" = Get-TerraformMapValue "ansible_bastion_private_ips" "card-ansible-bastion-server"
        "vpc" = "card"
    }
    "securities_ansible_bastion" = @{
        "ansible_host" = Get-TerraformMapValue "ansible_bastion_public_ips" "securities-ansible-bastion-server"
        "private_ip" = Get-TerraformMapValue "ansible_bastion_private_ips" "securities-ansible-bastion-server"
        "vpc" = "securities"
    }
    "common_ansible_bastion" = @{
        "ansible_host" = Get-TerraformMapValue "ansible_bastion_public_ips" "common-ansible-bastion-server"
        "private_ip" = Get-TerraformMapValue "ansible_bastion_private_ips" "common-ansible-bastion-server"
        "vpc" = "common"
    }
}

$inventory = @"
all:
  children:
    ansible_bastion:
      hosts:
        card_ansible_bastion:
          ansible_host: $($hosts.card_ansible_bastion.ansible_host)
          private_ip: $($hosts.card_ansible_bastion.private_ip)
          vpc: $($hosts.card_ansible_bastion.vpc)
        securities_ansible_bastion:
          ansible_host: $($hosts.securities_ansible_bastion.ansible_host)
          private_ip: $($hosts.securities_ansible_bastion.private_ip)
          vpc: $($hosts.securities_ansible_bastion.vpc)
        common_ansible_bastion:
          ansible_host: $($hosts.common_ansible_bastion.ansible_host)
          private_ip: $($hosts.common_ansible_bastion.private_ip)
          vpc: $($hosts.common_ansible_bastion.vpc)
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: '$privateKeyFile'
        ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
"@

Set-Content -Path "inventory.yml" -Value $inventory -Encoding ascii
Write-Host "inventory.yml generated."
