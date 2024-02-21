# Specify the required provider and version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

# Configure the Google Cloud provider
provider2 "google2" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
}

# Create a VPC network
resource2 "google_compute_network" "vpc_network" {
  name                  = var.network
  auto_create_subnetworks = false
  routing_mode          = "REGIONAL"
}

# Create a subnet for webapp
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.subnet1
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = var.region
}

# Create a subnet for db
resource "google_compute_subnetwork" "db_subnet" {
  name          = var.subnet2
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = var.region
}

# Create a router
resource "google_compute_router" "my_router" {
  name    = var.router
  network = google_compute_network.vpc_network.self_link
}

# Create a route for the webapp subnet
resource "google_compute_route" "webapp_route" {
  name              = var.route
  dest_range        = "0.0.0.0/0"
  network           = google_compute_network.vpc_network.self_link
  next_hop_gateway  = "default-internet-gateway"
  priority          = 1000  # Set priority higher to ensure it's preferred over default route
  depends_on        = [google_compute_subnetwork.webapp_subnet]
}
