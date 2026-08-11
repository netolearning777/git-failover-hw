terraform {
  required_providers {
    yandex = {
     source = "yandex-cloud/yandex"
     version = ">= 0.200.0"
    }
  }
  required_version = ">=1.8.4"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key1.json")
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = "ru-central1-a"
}
