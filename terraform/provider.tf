terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.26.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "3.21.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}