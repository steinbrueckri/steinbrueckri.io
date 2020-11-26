#!/usr/bin/env bash
export PATH=$PATH:$HOME/bin
## Configuration #######################################################################################################
search_path="content/gallery/**"

## PreFlight checks ####################################################################################################
# Check if b2 command is available
if ! command -v b2 &> /dev/null
then
    echo "b2 could not be found"
    exit
fi

# check ENVs
[ -z "$B2_APPLICATION_KEY_ID" ] && echo "ERROR: B2_APPLICATION_KEY_ID is not set!" && exit 255
[ -z "$B2_APPLICATION_KEY" ] && echo "ERROR: B2_APPLICATION_KEY is not set!" && exit 255

## Flight ##############################################################################################################
for index in $(find $search_path -name 'index.md'); do
  # get basepath
  basepath=$(dirname "$index")
  target="$basepath/img/"
  source=$(cat "$index" | grep source_bucket | cut -d '"' -f2)
  if [ -z "$source" ]; then
      echo "no source find"
      continue
  fi
  echo "#########################################################"
  echo "File: $index"
  echo "BasePath: $basepath"
  echo "ImageFolder: $target"
  echo "Source: $source"
  b2 sync --delete --noProgress "$source" "$target"
done