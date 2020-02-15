#!/usr/bin/env bash

set -e
set -o pipefail
set -u

required_version="$(cat .swiftlint-version)"
install_location=./vendor

install() {
  if [ ! -d $install_location ]; then
    mkdir $install_location;
  fi;

  rm -f ./tmp/swiftlint ./tmp/swiftlint.zip

  curl --location --fail --retry 5 \
    https://github.com/realm/SwiftLint/releases/download/"$required_version"/portable_swiftlint.zip \
    --output $install_location/swiftlint.zip

  (
    cd $install_location
    unzip -o swiftlint.zip -d download > /dev/null
    mv download/swiftlint swiftlint
    rm -rf swiftlint.zip download
  )

  echo "Installed swiftlint locally"
}

if [ ! -x $install_location/swiftlint ]; then
  echo "swiftlint not installed"
  install
elif ! diff <(echo "$required_version") <($install_location/swiftlint version) > /dev/null; then
  install
fi
