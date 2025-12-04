terraform {
  required_providers {
    vy = {
      source  = "nsbno/vy"
      version = ">= 1.0.0, <2.0.0"
      # Check for the newest version here: https://registry.terraform.io/providers/nsbno/vy/latest
    }
  }
}

provider "vy" {
  environment = "test"
}
