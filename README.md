# Steinbrueck.io

[![CI Status](https://github.com/steinbrueckri/steinbrueckri.github.io/workflows/ci/badge.svg)](https://github.com/steinbrueckri/steinbrueckri.github.io/actions?query=workflow%3Aci)
[![Netlify Status](https://api.netlify.com/api/v1/badges/b784977d-1e18-4540-913e-3ba9b83ebe78/deploy-status)](https://app.netlify.com/sites/steinbrueck-io/deploys)
[![Website Status](https://img.shields.io/website-up-down-green-red/http/steinbrueck.io.svg)](https://updown.io/98wn)

## Build

- I use [`npm`](https://npm.com/) as package manager
- [`taskfile`](https://taskfile.dev/) as task runner
- [`hugo`](https://gohugo.io/) as static page generator
- [`rclone`](https://rclone.org/) to fetch the full resource images from object storage
- [Hetzner Object Storage](https://www.hetzner.com/storage/object-storage) (S3-compatible) as source for the full resource images
- [`GitHub actions`](https://github.com/features/actions) as CI/CD System

Hugo is pinned via `HUGO_VERSION` in [`Taskfile.yml`](./Taskfile.yml). CI runs inside the official
`ghcr.io/gohugoio/hugo` image, which ships exactly that version; locally you need the same version on your
`PATH` (`brew install hugo`). `task hugo-install` checks this and fails on a mismatch instead of building
with the wrong version. When bumping Hugo, change both `HUGO_VERSION` and the image tag in
[`ci.yml`](./.github/workflows/ci.yml).

There are two build goals `build` and `ci`. The `ci` goal is executed in the GitHub Actions workflow ([`ci.yml`](./.github/workflows/ci.yml)).

The `ci` goal calls the script [get_gallery_images.sh](./get_gallery_images.sh) which downloads the gallery images from
the Hetzner Object Storage bucket. By default each gallery is fetched from `<bucket>/<gallery title>` (i.e. the gallery
directory name), so no per-gallery configuration is needed. A gallery can override the source by setting a
`source_bucket: "bucket/path"` field in its `index.md`.
The script needs the environment variables `HETZNER_S3_ACCESS_KEY` and `HETZNER_S3_SECRET_KEY` (in CI these come from
GitHub secrets, locally from 1Password via the Taskfile).

Example (no `source_bucket` needed — derived from the title):

```yaml
---
title: "Street-01-2020"
date: "2020-01-03"
summary: ""
draft: false
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
# you can also use the Taskfile task, but in that case the name will be only the date
task new-blog
```

### Gallery

```sh
hugo new --kind gallery gallery/Street-$(date +%m-%Y)
# or if you want to set a name by our own ...
hugo new --kind gallery gallery/<NAME>
# you can also use the Taskfile task
task new-gallery
```
