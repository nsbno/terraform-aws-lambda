terraform {
  required_providers {
    vy = {
      source = "nsbno/vy"
      # Old versions of the Vy provider
      version = ">= 0.0.0, <1.0.0"
    }
  }
}

provider "vy" {
  environment = "test"
}
