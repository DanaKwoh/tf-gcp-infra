# Project Information
variable "project_id" {
    default = "csye6225-cloudcomputing-2024"
}
variable "credentials_file" { 
    default = "credentials.json"
}
variable "service_account" {
  default = "developer-dana@csye6225-cloudcomputing-2024.iam.gserviceaccount.com"
}

# VPC
variable "network"{
    default = "csye6225"
}
variable "auto_create"{
    default = false
}

# Subnets
variable "subnet1"{
    default = "webapp"
}
variable "subnet2"{
    default = "db"
}
variable "routing_mode"{
    default = "REGIONAL"
}
variable "ip_range1"{
    default = "192.168.1.0/24"
}
variable "if_private_ip" {
  default = true
}
variable "ip_range2"{
    default = "10.0.1.0/24"
}
variable "region" {
  default = "us-central1"
}
variable "subnet_proxy" {
  default = "proxy-only-subnet"
}
variable "proxy_ip" {
  default = "10.129.0.0/23"
}
variable "proxy_purpose" {
  default = "REGIONAL_MANAGED_PROXY"
}
variable "proxy_role" {
  default = "ACTIVE"
}

# Route
variable "route"{
    default = "route"
}
variable "next_gateway"{
    default = "default-internet-gateway"
}

# Firewalls
variable "firewall1"{
    default = "webapp-firewall"
}
variable "firewall2"{
    default = "ssh-firewall"
}
variable "firewall3"{
    default = "sql-firewall"
}
variable "firewall4"{
    default = "http-firewall"
}
variable "firewall5"{
    default = "proxy-firewall"
}
variable "firewall6"{
    default = "healthcheck-firewall"
}
variable "allow_port"{
    default = "8080"
}
variable "protocol"{
    default = "tcp"
}
variable "ssh_port"{
    default = "22"
}
variable "http_port"{
    default = "80"
}
variable "https_port"{
    default = "443"
}
variable "source_ranges"{
    default = "0.0.0.0/0"
}
variable "sql_port" {
  default = "3306"
}
variable "load_ranges" {
  default = ["130.211.0.0/22", "35.191.0.0/16"]
}
variable "firewall_direction" {
  default = "INGRESS"
}

# Cloud SQL instance
variable "mysql_name"{
    default = "mysql-instance"
}
variable "db_version"{
    default = "MYSQL_5_7"
}
variable "tier"{
    default = "db-custom-1-3840"
}
variable "disk_type"{
    default = "PD_SSD"
}
variable "disk_size"{
    default = 100
}
variable "availability_type"{
    default = "REGIONAL"
}
variable "if_ipv4_enabled"{
    default = false
}
variable "if_binary_log_enabled"{
    default = true
}
variable "if_back_up"{
    default = true
}
variable "if_delete"{
    default = false
}

# Database
variable "user_name"{
    default = "webapp"
}
variable "db_name"{
    default = "webapp"
}

# Resreved Private ip
variable "private_ip_name" {
  default = "private-service-ip"
}
variable "private_ip_purpose" {
  default = "VPC_PEERING"
}
variable "private_ip_address_type" {
  default = "INTERNAL"
}
variable "private_ip_version" {
  default = "IPV4"
}
variable "private_ip_prefix_length" {
  default = 16
}
variable "static_ip_name" {
  default = "static-ip"
}

# Global Address ip
variable "global_ip_name" {
  default = "load-balancer"
}
variable "global_ip_type" {
  default = "EXTERNAL"
}

# Forwarding Rule
variable "fr_name" {
  default = "webapp-forwarding-rule"
}
variable "ip_protocol" {
  default = "TCP"
}
variable "fr_name2" {
  default = "https-forwarding-rule"
}

# SSL Certificate
variable "ssl_name" {
  default = "ssl-webapp"
}
variable "domain" {
  default = "csye6225webapp.online"
}
# HTTPS Proxy
variable "proxy_name" {
  default = "webapp-proxy"
}
# URL Map
variable "url_name" {
  default = "webapp-url-map"
}
# Health Check
variable "check_name" {
  default = "webapp-healthcheck"
}
variable "check_path" {
  default = "/healthz"
}
# Backend
variable "backend_name" {
  default = "webapp-backend-service"
}
variable "app_port" {
  default = 8080
}
variable "balancing_mode" {
  default = "UTILIZATION"
}
# Service Account
variable "ser_acc_id" {
  default =  "vm-logging"
}
variable "ser_acc_dis" {
  default = "VM Logging"
}
variable "service_scope" {
  default = ["https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write"]
}

# Compute Instance (VM)
variable "zone" {
  default = "us-central1-c"
}
variable "server_name"{
    default = "web-server"
}
variable "machine_type"{
    default = "n1-standard-2"
}
variable "server_tag"{
    default = ["http-server"]
}
variable "image"{
    default = "debian-cloud/debian-11" # This was "custom-image"
}
variable "image_size"{
    default = 100
}
variable "image_type"{
    default = "pd-balanced"
}
variable "sql_connection_name" {
  default = "cyse6225-cloudcomputing-webapp:us-central1:mysql-instance"
}
variable "on_host_maintenance" {
  default = "MIGRATE"
}
variable "provisioning_model" {
  default = "STANDARD"
}

# MIG
variable "mig_name" {
  default = "webapp-manager"
}
variable "version_name" {
  default = "primary"
}
variable "base_instance_name" {
  default = "vm"
}

# Autoscaling
variable "scaler_name" {
  default = "webapp-autoscaler"
}

# DNS
variable "dns_name" {
  default = "csye6225webapp.online."
}
variable "dns_zone" {
  default = "csye6225-webapp"
}
variable "dns_type" {
  default = "A"
}


# variable "image_id" {
#   description = "read output from Packer"
# }