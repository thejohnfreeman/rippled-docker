#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Parameters

BOOST_VERSION=${BOOST_VERSION:-1.70.0}

# Do not add a stanza to this script without explaining why it is here.

apt-get update
# Iteratively build the list of packages to install so that we can interleave
# the lines with comments explaining their inclusion.
dependencies=''
# - for adding apt sources for CMake and Clang
dependencies+=' curl dpkg-dev apt-transport-https ca-certificates gnupg software-properties-common'
# - Python headers for Boost.Python
dependencies+=' libpython-dev'
# - for downloading rippled and submodules
dependencies+=' git'
# - CMake generators (but not CMake itself)
dependencies+=' make ninja-build'
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

# Add source for CMake.
curl https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
# Add sources for Clang.
cat <<EOF >/etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
EOF
# Enumerate dependencies.
dependencies=''
# - CMake
dependencies+=' cmake'
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
boost_slug="boost_$(echo ${BOOST_VERSION} | tr . _)"
curl --location --remote-name \
  "https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/${boost_slug}.tar.gz"
tar xzf ${boost_slug}.tar.gz
rm ${boost_slug}.tar.gz

# Build and install Boost.
cd ${boost_slug}
# Must name our installation prefix here. The default is `/usr/local`.
./bootstrap.sh
./b2 -j $(nproc) install
cd ..
rm --recursive --force ${boost_slug}

# Clean up.
apt-get clean
