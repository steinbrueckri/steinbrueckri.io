---
title: "Terraform — Deploy 🚀 SSH 🔑"
summary: "Terraform — Deploy 🚀 SSH 🔑"
date: "2019-07-13"
draft: false
tags: ["Terraform", "write_it_down_to_remember"]
---

a new post from the category **write_it_down_to_remember**. ;)
I have found this snippet on my Trello board and wanted to remember it for later. In Case you need a solution to manage an ssh key for a Service Account for example for Ansible you can use this below.

```sh
# ssh key via variable
resource "google_compute_instance" "via-variable" {
  name         = "via-variable"
  machine_type = "n1-standard-1"
  zone         = "europe-west4-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_key_pub}"
    enable-oslogin = "FALSE" # to be sure OS Login is disabled for this instance
  }
}

# ssh key via file
resource "google_compute_instance" "via-file" {
  name         = "via-file"
  machine_type = "n1-standard-1"
  zone         = "europe-west4-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "ansible:${file("./files/ssh_key.pub")}"
    enable-oslogin = "FALSE" # to be sure OS Login is disabled for this instance
  }
}
```

**Caution**: With enabled OS Login on instances disables metadata-based SSH key configurations on those instances or project.