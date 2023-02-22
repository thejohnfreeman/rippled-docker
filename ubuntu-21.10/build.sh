#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Parameters

BOOST_VERSION=${BOOST_VERSION:-1.77.0}
GCC_VERSION=${GCC_VERSION:-11}
CLANG_VERSION=${CLANG_VERSION:-13}
CMAKE_VERSION=${CMAKE_VERSION:-3.21.0}
DOXYGEN_VERSION=${DOXYGEN_VERSION:-1.9.2}

# Do not add a stanza to this script without explaining why it is here.

apt-get update
# Non-interactively install tzdata.
# https://stackoverflow.com/a/44333806/618906
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends tzdata
# Iteratively build the list of packages to install so that we can interleave
# the lines with comments explaining their inclusion.
dependencies=''
# - for identifying the Ubuntu version
dependencies+=' lsb-release'
# - for adding apt sources for Clang
dependencies+=' curl dpkg-dev apt-transport-https ca-certificates gnupg software-properties-common'
# - Python headers for Boost.Python
dependencies+=' python-dev'
# - for downloading rippled and submodules
dependencies+=' git'
# - CMake generators (but not CMake itself)
dependencies+=' make ninja-build'
# - compilers
dependencies+=" gcc-${GCC_VERSION} g++-${GCC_VERSION}"
# - rippled dependencies
dependencies+=' protobuf-compiler libprotobuf-dev libssl-dev pkg-config'
# - documentation dependencies
dependencies+=' flex bison graphviz plantuml'
apt-get install --yes ${dependencies}

UBUNTU_CODENAME=$(lsb_release --short --codename)

# Give us nice unversioned aliases for gcc and company.
update-alternatives --install \
  /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} \
  --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-${GCC_VERSION} \
  --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-${GCC_VERSION} \
  --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-${GCC_VERSION} \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-${GCC_VERSION} \
  --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-${GCC_VERSION} \
  --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-${GCC_VERSION}
update-alternatives --auto gcc

# The package `gcc` depends on the package `cpp`, but the alternative
# `cpp` is a master alternative already, so it must be updated separately.
update-alternatives --install \
  /usr/bin/cpp cpp /usr/bin/cpp-${GCC_VERSION} 100
update-alternatives --auto cpp

# Add sources for Clang.
curl --location https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/${UBUNTU_CODENAME}/ llvm-toolchain-${UBUNTU_CODENAME}-${CLANG_VERSION} main
deb-src http://apt.llvm.org/${UBUNTU_CODENAME}/ llvm-toolchain-${UBUNTU_CODENAME}-${CLANG_VERSION} main
EOF
# Enumerate dependencies.
dependencies=''
# - clang, clang++, clang-tidy, clang-format
dependencies+=" clang-${CLANG_VERSION} clang-tidy-${CLANG_VERSION} clang-format-${CLANG_VERSION}"
# - libclang for Doxygen
dependencies+=" libclang-${CLANG_VERSION}-dev"
apt-get update
apt-get install --yes ${dependencies}

# Give us nice unversioned aliases for clang and company.
update-alternatives --install \
  /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 \
  --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION}
update-alternatives --auto clang
update-alternatives --install \
  /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-${CLANG_VERSION} 100
update-alternatives --auto clang-tidy
update-alternatives --install \
  /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_VERSION} 100
update-alternatives --auto clang-format

# Download and unpack CMake.
cmake_slug="cmake-${CMAKE_VERSION}"
curl --location --remote-name \
  "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${cmake_slug}.tar.gz"
tar xzf ${cmake_slug}.tar.gz
rm ${cmake_slug}.tar.gz

# Build and install CMake.
cd ${cmake_slug}
./bootstrap --parallel=$(nproc)
make -j $(nproc)
make install
cd ..
rm --recursive --force ${cmake_slug}

# Download and unpack Boost.
boost_slug="boost_$(echo ${BOOST_VERSION} | tr . _)"
curl --location --remote-name \
  "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/${boost_slug}.tar.gz"
tar xzf ${boost_slug}.tar.gz
rm ${boost_slug}.tar.gz

# Build and install Boost.
cd ${boost_slug}
# Must name our installation prefix here. The default is `/usr/local`.
./bootstrap.sh
./b2 -j $(nproc) install
cd ..
rm --recursive --force ${boost_slug}

# Download and unpack Doxygen.
doxygen_slug="doxygen-${DOXYGEN_VERSION}"
curl --location --remote-name \
  "http://doxygen.nl/files/${doxygen_slug}.src.tar.gz"
tar xzf ${doxygen_slug}.src.tar.gz
rm ${doxygen_slug}.src.tar.gz

# Build and install Doxygen.
cd ${doxygen_slug}
mkdir build
cd build
cmake -G Ninja -Duse_libclang=ON ..
cmake --build . --parallel $(nproc)
cmake --build . --target install
cd ../..
rm --recursive --force ${doxygen_slug}

# Clean up.
apt-get clean
