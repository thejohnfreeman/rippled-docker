#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Parameters

gcc_version=${GCC_VERSION:-11}
clang_version=${CLANG_VERSION:-14}
cmake_version=${CMAKE_VERSION:-3.25.1}
doxygen_version=${DOXYGEN_VERSION:-1.9.5}
conan_version=${CONAN_VERSION:-1.58}

# Do not add a stanza to this script without explaining why it is here.

apt update
# Non-interactively install tzdata.
# https://stackoverflow.com/a/44333806/618906
DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends tzdata
# Iteratively build the list of packages to install so that we can interleave
# the lines with comments explaining their inclusion.
dependencies=''
# - to identify the Ubuntu version
dependencies+=' lsb-release'
# - to download CMake
dependencies+=' curl'
# - to build CMake
dependencies+=' libssl-dev'
# - Python headers for Boost.Python
dependencies+=' python3.10-dev'
# - to install Conan
dependencies+=' python3-pip'
# - to download rippled
dependencies+=' git'
# - CMake generators (but not CMake itself)
dependencies+=' make ninja-build'
# - compilers
dependencies+=" gcc-${gcc_version} g++-${gcc_version}"
# - documentation dependencies
dependencies+=' flex bison graphviz plantuml'
apt install --yes ${dependencies}

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

ubuntu_codename=$(lsb_release --short --codename)

# Add sources for Clang.
curl --location https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/${ubuntu_codename}/ llvm-toolchain-${ubuntu_codename}-${clang_version} main
deb-src http://apt.llvm.org/${ubuntu_codename}/ llvm-toolchain-${ubuntu_codename}-${clang_version} main
EOF
# Enumerate dependencies.
dependencies=''
# - clang, clang++, clang-tidy, clang-format
dependencies+=" clang-${clang_version} clang-tidy-${clang_version} clang-format-${clang_version}"
# - libclang for Doxygen
dependencies+=" libclang-${clang_version}-dev"
apt update
apt install --yes ${dependencies}

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
curl --location --remote-name \
  "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/${cmake_slug}.tar.gz"
tar xzf ${cmake_slug}.tar.gz
rm ${cmake_slug}.tar.gz

# Build and install CMake.
cd ${cmake_slug}
./bootstrap --parallel=$(nproc)
make -j $(nproc)
make install
cd ..
rm --recursive --force ${cmake_slug}

# Download and unpack Doxygen.
doxygen_slug="doxygen-${doxygen_version}"
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

# Install Conan.
pip3 install conan==${conan_version}

conan profile new --detect gcc
conan profile update settings.compiler=gcc gcc
conan profile update settings.compiler.version=${gcc_version} gcc
conan profile update settings.compiler.libcxx=libstdc++11 gcc
conan profile update settings.compiler.cppstd=20 gcc
conan profile update env.CC=/usr/bin/gcc gcc
conan profile update env.CXX=/usr/bin/g++ gcc

conan profile new --detect clang
conan profile update settings.compiler=clang clang
conan profile update settings.compiler.version=${clang_version} clang
conan profile update settings.compiler.libcxx=libstdc++11 clang
conan profile update settings.compiler.cppstd=20 clang
conan profile update env.CC=/usr/bin/clang clang
conan profile update env.CXX=/usr/bin/clang++ clang

# Clean up.
apt clean
