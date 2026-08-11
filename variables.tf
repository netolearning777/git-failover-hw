variable "cloud_id" {
  type    = string
  default = "b1ghj0t1ivbs4rhd1efk"
}

variable "folder_id" {
  type    = string
  default = "b1gk8h2tv72651gd7rdv"
}

variable "zones" {
  type    = list(string)
  default = ["ru-central1-a", "ru-central1-e"]
}

variable "flow" {
  type    = string
  default = "24-01"
}
