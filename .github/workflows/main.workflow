workflow "Deploy to GitHub Pages" {
  on = "push"
  resolves = ["rpc-ping"]
}

action "hugo-deploy-gh-pages" {
  uses = "khanhicetea/gh-actions-hugo-deploy-gh-pages@master"
  secrets = [
    "GIT_DEPLOY_KEY",
  ]
  env = {
    HUGO_VERSION = "0.53"
  }
}

action "rpc-ping" {
  uses = "khanhicetea/gh-actions-rpc-ping@master"
  env = {
    PING_TITLE = "Hi, i'm Richard!"
    PING_URL = "https://steinbrueckri.github.io"
  }
  needs = ["hugo-deploy-gh-pages"]
}
