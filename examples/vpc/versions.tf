terraform {
  required_providers {
    vy = {
      source  = "nsbno/vy"
      version = "0.4.0"
    }
  }
}

provider "vy" {
  environment = "test"
}
