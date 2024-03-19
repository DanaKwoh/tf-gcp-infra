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

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                  = var.network
  auto_create_subnetworks = var.auto_create
  routing_mode          = var.routing_mode
}

# Create a subnet for webapp
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.subnet1
  ip_cidr_range = var.ip_range1
  network       = google_compute_network.vpc_network.self_link
  region        = var.region
  private_ip_google_access = var.if_private_ip
}

# Create a route for the webapp subnet
resource "google_compute_route" "webapp_route" {
  name              = var.route
  dest_range        = var.source_ranges
  network           = google_compute_network.vpc_network.self_link
  next_hop_gateway  = var.next_gateway
  priority          = 1000  # Set priority higher to ensure it's preferred over default route
  depends_on        = [google_compute_subnetwork.webapp_subnet]
}

# Create firewall rules
resource "google_compute_firewall" "webapp_firewall" {
  name    = var.firewall1
  network = google_compute_network.vpc_network.name
  allow {
    protocol = var.protocol
    ports    = [var.allow_port]
  }
  source_ranges = [var.source_ranges]
}
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
  # source_ranges = [var.source_ranges]
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
  lifecycle {
    create_before_destroy = true 
    prevent_destroy = false
  }
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
# Generate a random password for Cloud SQL user
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

resource "google_dns_record_set" "DNS" {
  name         = "csye6225webapp.online."
  type         = "A"
  ttl          = 300
  managed_zone = "csye6225-webapp"

  rrdatas = [google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip]
}