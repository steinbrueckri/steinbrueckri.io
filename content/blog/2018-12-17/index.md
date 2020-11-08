---
title: "Ship 🚚 Docker Images via SSH"
summary: "Ship 🚚 Docker Images via SSH"
date: "2018-12-17"
draft: false
tags: ["write_it_down_to_remember"]
---

a new post from the category **write_it_down_to_remember**. ;)
Sometimes not possible to deliver a Docker image via a Docker-Registry, in my case I need to debug an issue in PROD. For this, I need to rebuild the used image and to run the image on the QA System. So I build the Image on my Local MacBook and deliver the image to the System via SSH see below.

```sh
# docker save | streamed images to STDOUT
# bzip2       | compress image an the fly
# pv          | show progress bar
# ssh         | forward stream to remote host
# bunzip2     | decompress on remote host
# docker load | reimport on remote host

docker save <image> | bzip2 | pv | ssh user@host 'bunzip2 | docker load'
```