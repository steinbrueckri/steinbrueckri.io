---
title: "GKE-Interconnect subnetwork is already used"
summary: "My First Post"
date: "2020-10-03"
draft: false
tags: ["Terraform", "Kubernetes", "GCP", "Network"]
---

## The Problem
Terraform cannot create a GKE cluster because of the error message "Error waiting for creating GKE cluster: Retry budget exhausted (10 attempts)"

```sh
Error: Error applying plan:
1 error occurred:
* module.k8s.google_container_cluster.cluster: 1 error occurred:
* google_container_cluster.cluster: Error waiting for creating GKE cluster: Retry budget exhausted (10 attempts): Services range "sn-w1–3021-svc" in network "gc-4509-work", subnetwork "sn-w1–3021" is already used by another cluster.
```
## But why?
As the error message says, the subnetwork "sn-w1–3021" is already used by another cluster. Keep in mind we use a shared VPC from a Interconnect!
But we cannot find a GKE Cluster how is using this network. After some Analyses and reach out to the Google support we have notified that when you are deploying a GKE Cluster in an Interconnect Network, the GKE Cluster to Network Mapping is written to the Project Metadata of the Interconnect Project in our case 'v135–4509-interconnect-work'.
Why this is happening?
We have tried to reproduce the behavior and if you Create and destroy the GKE Cluster via WebUI, Gcloud or Terraform you don't have any issues, In your case the cluster was deleted by project shutdown, this cause the metadata was not properly cleaned up upon cluster deletion.
It's not clear to us if the problem is not solved on Google side or not. If you have the same problem, please drop a comment below.

## How to solve this issue?
- Configure the gcloud CLI to use the Interconnect project.

```sh
$ gcloud config set project v135–4509-interconnect-work
Updated property [core/project].
```

- Check the metadata of the project

```sh
$ gcloud compute project-info describe | grep -B 1 sn-w1–3021
value: services:gc-4509-work:sn-w1–3021:sn-w1–3021-svc,shareable-pods:gc-4509-work:sn-w1–3021:sn-w1–3021-pod
```

- As you can see above we find a record, now we need to delete this key-value pair.

```sh
$ gcloud compute project-info remove-metadata - keys gke-cluster-b839e91a-secondary-ranges
Updated [https://www.googleapis.com/compute/v1/projects/v135-4509-interconnect-work].
```

- now we can retry our terraform apply and now it works 🙌

## Additional information
- [Remove Metadata](https://cloud.google.com/sdk/gcloud/reference/compute/project-info/remove-metadata)
- [Google Support Case](https://console.cloud.google.com/support/cases/detail/19527106)
- [Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/how-to/dedicated/using-interconnects-other-projects)