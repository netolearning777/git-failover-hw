# Создание сетевого балансировщика (слушает порт 80, healthcheck на порт 80)
resource "yandex_lb_network_load_balancer" "nlb" {
  name = "web-network-balancer"

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

# Вывод публичного IP-адреса балансировщика для проверки
output "load_balancer_public_ip" {
  description = "Публичный IP-адрес сетевого балансировщика"
  value       = one(one(yandex_lb_network_load_balancer.nlb.listener).external_address_spec).address
}
