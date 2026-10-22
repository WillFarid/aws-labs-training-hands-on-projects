# Enterprise Best Practice: Prevents state corruption and allows team collaboration
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}