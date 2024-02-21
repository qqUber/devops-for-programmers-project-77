terraform {
  cloud {
    organization = "qquber"
    workspaces {
      name = "qquber"
    }
  }

  required_version = ">= 1.1.0"
}