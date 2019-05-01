#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Do not add a stanza to this script without explaining why it is here.

apt-get update
# Iteratively build the list of packages to install so that we can interleave
# the lines with comments explaining their inclusion.
dependencies=''
# - for adding apt sources for Clang
dependencies+=' dpkg-dev'
# - for downloading Boost
dependencies+=' wget'
# - Python headers for Boost.Python
dependencies+=' libpython-dev'
# - for downloading rippled and submodules
dependencies+=' git'
# - CMake and generators
dependencies+=' cmake make ninja-build'
# - compilers
dependencies+=' gcc-8 g++-8'
# - rippled dependencies
dependencies+=' protobuf-compiler libprotobuf-dev libssl-dev'
apt-get install --yes ${dependencies}

# Give us nice unversioned aliases for gcc-8 and company.
update-alternatives --install \
  /usr/bin/gcc gcc /usr/bin/gcc-8 100 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
  --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-8 \
  --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-8 \
  --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-8 \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-8 \
  --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-8 \
  --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-8
update-alternatives --auto gcc

# The package `gcc-8` depends on the package `cpp-8`, but the alternative
# `cpp` is a master alternative already, so it must be updated separately.
update-alternatives --install \
  /usr/bin/cpp cpp /usr/bin/cpp-8 100
update-alternatives --auto cpp

# Add sources for Clang.
cat <<EOF >/etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
EOF
# Enumerate dependencies.
dependencies=''
# - clang and clang++
dependencies+=' clang-7'
# Install Clang.
apt-get install --yes ${dependencies}

# Give us nice unversioned aliases for clang-7 and company.
update-alternatives --install \
  /usr/bin/clang clang /usr/bin/clang-7 100 \
  --slave /usr/bin/clang++ clang++ /usr/bin/clang++-7
update-alternatives --auto clang

# Download and unpack Boost.
wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz
tar xzf boost_1_67_0.tar.gz
rm boost_1_67_0.tar.gz

# Build and install Boost.
cd boost_1_67_0
# Must name our installation prefix here. The default is `/usr/local`.
./bootstrap.sh
./b2 -j $(nproc) install
cd ..
rm -rf boost_1_67_0

# Clean up.
apt-get clean
