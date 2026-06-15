terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }


}

provider "azurerm" {
  features {
    key_vault {
      # 실습 후 destroy 시 Key Vault 완전 삭제 (비용 절감)
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
    resource_group {
      # 리소스 그룹 안에 리소스가 있어도 삭제 허용
      prevent_deletion_if_contains_resources = false
    }
  }
}
