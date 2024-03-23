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
    default = "assignment-6"
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
variable "source_ranges"{
    default = "0.0.0.0/0"
}
variable "sql_port" {
  default = "3306"
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
    default = "custom-image"
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