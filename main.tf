provider "random" {}

resource "random_pet" "project_suffix" {
  length = 2
}

locals {
  project_name = "terraform-starter-${random_pet.project_suffix.id}"
}
