# Steinbrueck.io

[![CI Status](https://github.com/steinbrueckri/steinbrueckri.github.io/workflows/ci/badge.svg)](https://github.com/steinbrueckri/steinbrueckri.github.io/actions?query=workflow%3Aci)
[![Netlify Status](https://api.netlify.com/api/v1/badges/b784977d-1e18-4540-913e-3ba9b83ebe78/deploy-status)](https://app.netlify.com/sites/steinbrueck-io/deploys)
[![Website Status](https://img.shields.io/website-up-down-green-red/http/steinbrueck.io.svg)](https://updown.io/98wn)

## Build

- I use [`npm`](https://npm.com/) as package manager
- [`taskfile`](https://taskfile.dev/) as task runner
- [`hugo`](https://gohugo.io/) as static page generator
- [`B2`](https://www.backblaze.com/b2/cloud-storage.html) as source for the full resource images
- [`GitHub actions`](https://github.com/features/actions) as CI/CD System

It exist two build goals `build` and `ci`, the `ci` goal is obviously executed in the Github actions workflow ([`ci.yml`](./ci.yml)).

The `ci` goal calls the script [get_gallery_images.sh](./get_gallery_images.sh) this script will download the images for
the gallery's from the B2 Bucket (`source_bucket`) specific in the gallery index.md.
The script needs some environment variables to be set `B2_APPLICATION_KEY_ID` and `B2_APPLICATION_KEY`.

Example:

```yaml
---
title: "Street-01-2020"
date: "2020-01-03"
summary: ""
draft: false
source_bucket: "b2://steinbrueck-io-gallery/Street-01-2020"
tags: ["Street", "BW", "Erfurt", "Ingolstadt", "Nuernberg"]
---
```

## Screenshot

![](https://api.microlink.io?url=https%3A%2F%2Fsteinbrueck.io&overlay.browser=none&overlay.background=%23c1c1c1&screenshot=true&meta=false&embed=screenshot.url)
![](https://api.microlink.io?url=https%3A%2F%2Fsteinbrueck.io%2Fgallery&overlay.browser=none&overlay.background=%23c1c1c1&screenshot=true&meta=false&embed=screenshot.url)
![](https://api.microlink.io?url=https%3A%2F%2Fsteinbrueck.io%2Fblog&overlay.browser=none&overlay.background=%23c1c1c1&screenshot=true&meta=false&embed=screenshot.url)

## Create

### Blog

```sh
hugo new --kind blog blog/Foobar-$(date +%Y-%m-%d)
# you can also use a gulp task but in this case the name will be only the date
task new-blog
```

### Gallery

```sh
hugo new --kind gallery gallery/Street-$(date +%m-%Y)
# or if you want to set a name by our own ...
hugo new --kind gallery gallery/<NAME>
# you can also use a gulp task
task new-gallery
```
