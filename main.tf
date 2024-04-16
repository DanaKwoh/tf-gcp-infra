# Specify the required provider and version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.20.0"
    }
  }
}
# Configure the Google Cloud provider
provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

# VPC network
resource "google_compute_network" "vpc_network" {
  name                  = var.network
  auto_create_subnetworks = var.auto_create
  routing_mode          = var.routing_mode
}
# Subnet for webapp
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.subnet1
  ip_cidr_range = var.ip_range1
  network       = google_compute_network.vpc_network.self_link
  region        = var.region
  private_ip_google_access = var.if_private_ip
}
# Route for the webapp subnet
resource "google_compute_route" "webapp_route" {
  name              = var.route
  dest_range        = var.source_ranges
  network           = google_compute_network.vpc_network.self_link
  next_hop_gateway  = var.next_gateway
  priority          = 1000  # Set priority higher to ensure it's preferred over default route
  depends_on        = [google_compute_subnetwork.webapp_subnet]
}
# Firewall
resource "google_compute_firewall" "ssh_firewall" {
  name    = var.firewall2
  network = google_compute_network.vpc_network.name
  allow {
    protocol = var.protocol
    ports    = [var.ssh_port]
  }
  source_ranges = [var.source_ranges]
}
resource "google_compute_firewall" "sql_firewall" {
  name    = var.firewall3
  network = google_compute_network.vpc_network.name
  allow {
    protocol = var.protocol
    ports    = [var.sql_port]
  }
  source_ranges = [google_compute_subnetwork.webapp_subnet.ip_cidr_range]
}
# Private services connection
resource "google_compute_global_address" "private_ip_block" {
  name         = var.private_ip_name
  purpose      = var.private_ip_purpose
  address_type = var.private_ip_address_type
  ip_version   = var.private_ip_version
  prefix_length = var.private_ip_prefix_length
  network       = google_compute_network.vpc_network.self_link
}
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}
# CloudSQL Instance
resource "google_sql_database_instance" "mysql" {
  name                = var.mysql_name
  region              = var.region
  database_version    = var.db_version 
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier               = var.tier
    disk_type          = var.disk_type
    disk_size          = var.disk_size
    availability_type  = var.availability_type
    ip_configuration {
      ipv4_enabled     = var.if_ipv4_enabled
      private_network  = google_compute_network.vpc_network.id
    }
    backup_configuration {
      binary_log_enabled = var.if_binary_log_enabled
      enabled            = var.if_back_up
    }
  }
  deletion_protection = var.if_delete
}
# Random password for Cloud SQL user
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
# DB User
resource "google_sql_user" "users" {
  name     = var.user_name
  instance = google_sql_database_instance.mysql.name
  password = random_password.password.result
}
# Database
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.mysql.name
}

# Subnet for proxy
resource "google_compute_subnetwork" "proxy_only" {
  name          = var.subnet_proxy
  ip_cidr_range = var.proxy_ip
  network       = google_compute_network.vpc_network.id
  purpose       = var.proxy_purpose
  region        = var.region
  role          = var.proxy_role
}
# Firewalls
resource "google_compute_firewall" "allow_proxy" {
  name = var.firewall5
  allow {
    ports    = [var.https_port]
    protocol = var.protocol
  }
  allow {
    ports    = [var.http_port]
    protocol = var.protocol
  }
  allow {
    ports    = [var.allow_port]
    protocol = var.protocol
  }
  direction     = var.firewall_direction
  network       = google_compute_network.vpc_network.name
  priority      = 1000
  source_ranges = [google_compute_global_address.default.address]
}
resource "google_compute_firewall" "health_check" {
  name = var.firewall6
  allow {
    protocol = var.protocol
  }
  direction     = var.firewall_direction
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = var.load_ranges
}
# Global Address
resource "google_compute_global_address" "default" {
  name          = var.global_ip_name
  address_type  = var.global_ip_type 
}
# Forwarding Rule 8080
resource "google_compute_global_forwarding_rule" "app" {
  name       = var.fr_name
  depends_on = [google_compute_subnetwork.proxy_only]
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.global_ip_type
  port_range            = var.allow_port
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.address
}
# Forwarding Rule 443
resource "google_compute_global_forwarding_rule" "https" {
  name       = var.fr_name2
  depends_on = [google_compute_subnetwork.proxy_only]
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.global_ip_type
  port_range            = var.https_port
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.address
}
# SSL Certificate
resource "google_compute_managed_ssl_certificate" "lb_default" {
  name     = var.ssl_name
  managed {
    domains = [var.domain]
  }
}
# HTTPS Proxy
resource "google_compute_target_https_proxy" "default" {
  name    = var.proxy_name
  url_map = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.id
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}
# URL Map
resource "google_compute_url_map" "default" {
  name            = var.url_name
  default_service = google_compute_backend_service.default.id
}
# Health Check
resource "google_compute_health_check" "default" {
  name               = var.check_name
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port               = var.app_port
    request_path       = var.check_path
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}
# backend service 
resource "google_compute_backend_service" "default" {
  name                  = var.backend_name
  load_balancing_scheme = var.global_ip_type
  health_checks         = [google_compute_health_check.default.id]
  protocol              = "HTTP"
  session_affinity      = "NONE"
  timeout_sec           = 30
  backend {
    group           = google_compute_instance_group_manager.default.instance_group
    balancing_mode  = var.balancing_mode
    capacity_scaler = 1.0
  }
}

# Compute Instance Template
resource "google_compute_instance_template" "web_server_template" {
  name         = var.server_name
  project      = var.project_id
  machine_type = var.machine_type
  region       = var.region
  tags         = ["web-server"]
  disk {
    source_image = var.image
    disk_size_gb  = var.image_size
    disk_type  = var.image_type
    auto_delete  = true
    boot         = true
  }
  labels = {
    managed-by-cnrm = "true"
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
    access_config {}
  }
  metadata_startup_script = <<-SCRIPT
    # Create .env file and assign configurations
    cat << EOF > /opt/csye6225/.env
    MYSQL_HOST=127.0.0.1
    MYSQL_PORT=${var.sql_port}
    PORT=${var.allow_port}
    DB_NAME=${google_sql_database.database.name}
    DB_USER=${google_sql_user.users.name}
    DB_PASSWORD=${google_sql_user.users.password}
    EOF
    
    # Download and make the Cloud SQL Proxy executable
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.9.0/cloud-sql-proxy.linux.amd64
    sleep 3
    chmod +x cloud-sql-proxy
    ./cloud-sql-proxy --private-ip --credentials-file /opt/csye6225/credentials.json ${google_sql_database_instance.mysql.connection_name} &
    sleep 5

    # Write a confirmation message
    echo 'Instance ready' > /tmp/instance_ready
    sudo systemctl stop webapp
    sudo systemctl start webapp
  SCRIPT
  # Service account
  service_account {
    email  = var.service_account
    scopes = var.service_scope
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = var.on_host_maintenance
    provisioning_model  = var.provisioning_model
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Compute Instance (VM)
resource "google_compute_instance" "web_server" {
  name         = var.server_name
  machine_type = var.machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.image
      size  = var.image_size
      type  = var.image_type
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
    access_config {}
  }
  metadata_startup_script = <<-SCRIPT
    # Create .env file and assign configurations
    cat << EOF > /opt/csye6225/.env
    MYSQL_HOST=127.0.0.1
    MYSQL_PORT=${var.sql_port}
    PORT=${var.allow_port}
    DB_NAME=${google_sql_database.database.name}
    DB_USER=${google_sql_user.users.name}
    DB_PASSWORD=${google_sql_user.users.password}
    EOF
    
    # Download and make the Cloud SQL Proxy executable
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.9.0/cloud-sql-proxy.linux.amd64
    sleep 3
    chmod +x cloud-sql-proxy
    ./cloud-sql-proxy --private-ip --credentials-file /opt/csye6225/credentials.json ${google_sql_database_instance.mysql.connection_name} &
    sleep 5

    # Write a confirmation message
    echo 'Instance ready' > /tmp/instance_ready
    sudo systemctl stop webapp
    sudo systemctl start webapp
  SCRIPT
  # Service account
  service_account {
    email  = var.service_account
    scopes = var.service_scope
  }
}


# MIG
resource "google_compute_instance_group_manager" "default" {
  name = var.mig_name
  zone = var.zone
  named_port {
    name = "http"
    port = var.app_port
  }
  version {
    instance_template = google_compute_instance_template.web_server_template.id
    name              = var.version_name
  }
  base_instance_name = var.base_instance_name
  target_size        = 2
}

# Autoscaling
resource "google_compute_autoscaler" "web_autoscaler" {
  name        = var.scaler_name
  zone        = var.zone
  target      = google_compute_instance_group_manager.default.id
  autoscaling_policy {
    max_replicas      = 6
    min_replicas      = 3
    cooldown_period   = 60
    cpu_utilization {
      target = 0.05
    }
  }
}

# DNS
resource "google_dns_record_set" "DNS" {
  name         = var.dns_name
  type         = var.dns_type
  ttl          = 300
  managed_zone = var.dns_zone
  rrdatas = [google_compute_global_address.default.address]
}


# resource "google_pubsub_topic" "verify_email_topic" {
#   name                           = "verify_email"
#   message_retention_duration     = "604800s" # 7 days
# }

# resource "google_pubsub_subscription" "verify_email_subscription" {
#   name  = "email_func"
#   topic = google_pubsub_topic.verify_email_topic.name
#   ack_deadline_seconds = 60
# }
# resource "google_storage_bucket" "my_bucket" {
#   name     = "csy6255-webapp-serverless"
#   location = var.region 
#   force_destroy = true
# }

# resource "google_storage_bucket_object" "function_source" {
#   name   = "email_func.zip"  # Name of the file inside the bucket
#   bucket = google_storage_bucket.my_bucket.name
#   source = "/Users/Dana_G/Documents/Code/NEU/CloudComputing/serverless/email_func.zip"
# }

# resource "google_cloudfunctions_function" "send_verification_email" {
#   name        = "emailPubSub"
#   description = "Cloud Function for sending verification emails"
#   runtime     = "nodejs18"

#   source_archive_bucket = google_storage_bucket.my_bucket.name
#   source_archive_object = google_storage_bucket_object.function_source.name

#   trigger_http = true
 
#   environment_variables = {
#     SENDGRID_API_KEY="8J4FAE1HYFZWQHEG6MK2WSDW"
#   }
  # event_trigger {
  #   event_type     = "providers/cloud.pubsub/eventTypes/topic.publish"
  #   resource       = google_pubsub_topic.verify_email_topic.id
  # }
  
# }

