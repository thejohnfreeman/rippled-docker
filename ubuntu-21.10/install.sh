#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Parameters

boost_version=${BOOST_VERSION:-1.77.0}
boost_sha256=5347464af5b14ac54bb945dc68f1dd7c56f0dad7262816b956138fc53bcc0131
gcc_version=${GCC_VERSION:-11}
clang_version=${CLANG_VERSION:-13}
cmake_version=${CMAKE_VERSION:-3.21.0}
cmake_sha256=4a42d56449a51f4d3809ab4d3b61fd4a96a469e56266e896ce1009b5768bd2ab
doxygen_version=${DOXYGEN_VERSION:-1.9.2}
doxygen_md5=84c0522bb65d17f9127896268b72ea2a

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
dependencies+=" gcc-${gcc_version} g++-${gcc_version}"
# - rippled dependencies
dependencies+=' protobuf-compiler libprotobuf-dev libssl-dev pkg-config'
# - documentation dependencies
dependencies+=' flex bison graphviz plantuml'
apt-get install --yes ${dependencies}

ubuntu_codename=$(lsb_release --short --codename)

# Give us nice unversioned aliases for gcc and company.
update-alternatives --install \
  /usr/bin/gcc gcc /usr/bin/gcc-${gcc_version} 100 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-${gcc_version} \
  --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-${gcc_version} \
  --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-${gcc_version} \
  --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-${gcc_version} \
  --slave /usr/bin/gcov gcov /usr/bin/gcov-${gcc_version} \
  --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-${gcc_version} \
  --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-${gcc_version}
update-alternatives --auto gcc

# The package `gcc` depends on the package `cpp`, but the alternative
# `cpp` is a master alternative already, so it must be updated separately.
update-alternatives --install \
  /usr/bin/cpp cpp /usr/bin/cpp-${gcc_version} 100
update-alternatives --auto cpp

# Add sources for Clang.
curl --location https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/llvm.list
deb https://apt.llvm.org/${ubuntu_codename}/ llvm-toolchain-${ubuntu_codename}-${clang_version} main
deb-src https://apt.llvm.org/${ubuntu_codename}/ llvm-toolchain-${ubuntu_codename}-${clang_version} main
EOF
# Enumerate dependencies.
dependencies=''
# - clang, clang++, clang-tidy, clang-format
dependencies+=" clang-${clang_version} clang-tidy-${clang_version} clang-format-${clang_version}"
# - libclang for Doxygen
dependencies+=" libclang-${clang_version}-dev"
apt-get update
apt-get install --yes ${dependencies}

# Give us nice unversioned aliases for clang and company.
update-alternatives --install \
  /usr/bin/clang clang /usr/bin/clang-${clang_version} 100 \
  --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${clang_version}
update-alternatives --auto clang
update-alternatives --install \
  /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-${clang_version} 100
update-alternatives --auto clang-tidy
update-alternatives --install \
  /usr/bin/clang-format clang-format /usr/bin/clang-format-${clang_version} 100
update-alternatives --auto clang-format

# Download and unpack CMake.
cmake_slug="cmake-${cmake_version}"
cmake_archive="${cmake_slug}.tar.gz"
curl --location --remote-name \
  "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/${cmake_archive}"
echo "${cmake_sha256}  ${cmake_archive}" | sha256sum --check
tar -xzf ${cmake_archive}
rm ${cmake_archive}

# Build and install CMake.
cd ${cmake_slug}
./bootstrap --parallel=$(nproc)
make -j $(nproc)
make install
cd ..
rm --recursive --force ${cmake_slug}

# Download and unpack Boost.
boost_slug="boost_$(echo ${boost_version} | tr . _)"
boost_archive="${boost_slug}.tar.gz"
curl --location --remote-name \
  "https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/${boost_archive}"
echo "${boost_sha256}  ${boost_archive}" | sha256sum --check
tar -xzf ${boost_archive}
rm ${boost_archive}

# Build and install Boost.
cd ${boost_slug}
# Must name our installation prefix here. The default is `/usr/local`.
./bootstrap.sh
./b2 -j $(nproc) install
cd ..
rm --recursive --force ${boost_slug}

# Download and unpack Doxygen.
doxygen_slug="doxygen-${doxygen_version}"
doxygen_archive="${doxygen_slug}.src.tar.gz"
curl --location --remote-name \
  "https://doxygen.nl/files/${doxygen_archive}"
echo "${doxygen_md5}  ${doxygen_archive}" | md5sum --check
tar -xzf ${doxygen_archive}
rm ${doxygen_archive}

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
