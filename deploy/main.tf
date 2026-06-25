terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  region = var.region
}

variable "region" {
  default = "eu-frankfurt-1"
}

variable "compartment_id" {
  description = "OCID kompartmenenta iz Oracle Console"
}

# VCN
resource "oci_core_vcn" "maria_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "maria-vcn"
  dns_label      = "mariavcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "maria_ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.maria_vcn.id
  display_name   = "maria-ig"
}

# Route Table
resource "oci_core_route_table" "maria_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.maria_vcn.id
  display_name   = "maria-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.maria_ig.id
  }
}

# Security List
resource "oci_core_security_list" "maria_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.maria_vcn.id
  display_name   = "maria-sl"
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# Subnet
resource "oci_core_subnet" "maria_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.maria_vcn.id
  cidr_block          = "10.0.1.0/24"
  display_name        = "maria-subnet"
  dns_label           = "mariasubnet"
  security_list_ids   = [oci_core_security_list.maria_sl.id]
  route_table_id      = oci_core_route_table.maria_rt.id
}

# Data source dlya Ubuntu 22.04 ARM
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VM Instance (Always Free ARM)
resource "oci_core_instance" "maria_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "maria-server"
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }
  source_details {
    source_type = "image"
    image_id    = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 200
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.maria_subnet.id
    assign_public_ip = true
  }
  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
  }
}

# Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

output "public_ip" {
  value = oci_core_instance.maria_server.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${oci_core_instance.maria_server.public_ip}"
}
