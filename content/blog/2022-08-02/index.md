---
title: "Delete all GitHub Actions runs"
summary: ""
date: "2022-08-02"
lastmod: "2022-08-02"
draft: false
tags: [GitHub, GH, GitHub-Actions, CI, CD]
---

Delete all GitHub action runs from an Repository.

`user=steinbrueckri repo=dotfiles; gh api repos/$user/$repo/actions/runs —paginate -q ‚.workflow_runs[].id‘ | xargs -n1 -I % gh api repos/$user/$repo/actions/runs/% -X DELETE`
