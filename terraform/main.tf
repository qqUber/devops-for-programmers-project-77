
variable "do_token" {}
variable "datadog_api_key" {}
variable "datadog_app_key" {}
variable "datadog_api_url" {}
variable "DOMAIN" {}
variable "PROJECT_NAME" {}

data "digitalocean_ssh_key" "mysshkey" {
  name = "mykey"
}

output "webservers" {
  value = digitalocean_droplet.web
}

resource "digitalocean_droplet" "web" {
  count  = 2
  image  = "ubuntu-22-10-x64"
  name   = "${var.PROJECT_NAME}-web-${count.index}"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.mysshkey.id
  ]
}

output "ansible_inventory" {
  value = templatefile(
    "${path.module}/inventory.tmpl",
    {
      webservers = digitalocean_droplet.web
    }
  )
}

resource "digitalocean_database_db" "db" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "${var.PROJECT_NAME}-db"
}

resource "digitalocean_database_cluster" "postgres" {
  name       = "${var.PROJECT_NAME}-postgres-cluster"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-1gb"
  region     = "fra1"
  node_count = 1
}

output "vault" {
  value = templatefile(
    "${path.module}/vault_generated.tmpl",
    {
      host            = digitalocean_database_cluster.postgres.private_host,
      port            = digitalocean_database_cluster.postgres.port,
      user            = digitalocean_database_cluster.postgres.user,
      password        = nonsensitive(digitalocean_database_cluster.postgres.password),
      database        = digitalocean_database_db.db.name,
      datadog_api_key = nonsensitive(var.datadog_api_key)
    }
  )
}

resource "digitalocean_record" "record" {
  domain = digitalocean_domain.domain.name
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.loadbalancer.ip
}

resource "digitalocean_domain" "domain" {
  name = var.DOMAIN
}

resource "digitalocean_certificate" "certificate" {
  name    = "${var.PROJECT_NAME}-certificate"
  type    = "lets_encrypt"
  domains = [digitalocean_domain.domain.name]
}

resource "digitalocean_loadbalancer" "loadbalancer" {
  name   = "${var.PROJECT_NAME}-loadbalancer"
  region = "fra1"

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  forwarding_rule {
    entry_protocol   = "https"
    entry_port       = 443
    target_protocol  = "http"
    target_port      = 80
    certificate_name = digitalocean_certificate.certificate.name
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  sticky_sessions {
    type               = "cookies"
    cookie_name        = "${var.PROJECT_NAME}_STICKY_COOKIE"
    cookie_ttl_seconds = 3600
  }
  redirect_http_to_https = true

  droplet_ids = digitalocean_droplet.web.*.id
}

resource "datadog_monitor" "healthcheck_monitor" {
  name         = "Servers healthcheck"
  type         = "service check"
  query        = "\"http.can_connect\".over(\"*\").by(\"*\").last(3).count_by_status()"
  message      = ""
  include_tags = false

  monitor_thresholds {
    warning  = 2
    critical = 2
    ok       = 2
  }
}