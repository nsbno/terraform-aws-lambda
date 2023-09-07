terraform {
  required_providers {
    vy = {
      source  = "nsbno/vy"
      version = "0.3.1"
    }
  }
}

provider "vy" {
  environment = "test"
}
