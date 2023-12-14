#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# This script exists to record which versions of software were installed in
# a container. Use it like this:
#
# $ image_id=$(docker build --quiet | tee /dev/tty)
# $ docker run --interactive ${image_id} bash <metadata.sh >metadata 2>&1

apt list --installed
gcc --version
clang --version
cmake --version
doxygen --version
conan --version
gcovr --version
