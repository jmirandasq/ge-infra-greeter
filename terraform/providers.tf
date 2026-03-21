terraform {
  required_version = ">= 1.6.0"

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.7.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "keycloak" {
  client_id     = "admin-cli"
  username      = var.keycloak_admin_user
  password      = var.keycloak_admin_password
  url           = var.keycloak_url
  realm         = "master"

  tls_insecure_skip_verify = var.tls_insecure
}
