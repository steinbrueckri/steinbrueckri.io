#!/usr/bin/env bash
export PATH=$PATH:$HOME/bin
## Configuration ###############################################################
SEARCH_PATH="content/gallery/**"
B2_APPLICATION_KEY_ID=$2
B2_APPLICATION_KEY=$3

## PreFlight checks ###########################################################
# Check if b2 command is available
if ! command -v b2 &> /dev/null
then
    echo "b2 could not be found"
    exit
fi

## Flight ######################################################################
for index in $(find $SEARCH_PATH -name 'index.md'); do
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
  b2 sync --delete --no-progress "$source" "$target"
done
