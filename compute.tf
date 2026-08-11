#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  hostname    = "bastion" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = var.zones[0] #зона ВМ должна совпадать с зоной subnet!

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("${path.module}/bastion-cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet[var.zones[0]].id #зона ВМ должна совпадать с зоной subnet!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}

# Создание двух идентичных виртуальных машин через count
resource "yandex_compute_instance" "web_vm" {
  count       = 2
  name        = "web-server${count.index+1}" # Имя ВМ в облачной консоли
  hostname    = "web-server${count.index+1}" # формирует FDQN имя хоста.
  platform_id = "standard-v3"
  zone        = var.zones[count.index] # зона ВМ должна совпадать с зоной subnet

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("${path.module}/web-cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet[var.zones[count.index]].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

# Создание таргет-группы
resource "yandex_lb_target_group" "tg" {
  name = "web-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.web_vm
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-XYZ
  [bastion]
  ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

  [webservers]
  %{ for vm in yandex_compute_instance.web_vm ~}
  ${vm.network_interface.0.ip_address}
  %{ endfor ~}
  XYZ
}
