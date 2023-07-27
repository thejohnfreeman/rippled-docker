#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Parameters

gcc_version=${GCC_VERSION:-11}
cmake_version=${CMAKE_VERSION:-3.25.1}
cmake_sha256=1c511d09516af493694ed9baf13c55947a36389674d657a2d5e0ccedc6b291d8
conan_version=${CONAN_VERSION:-1.60}

apt update
# Iteratively build the list of packages to install so that we can interleave
# the lines with comments explaining their inclusion.
dependencies=''
# - for add-apt-repository
dependencies+=' software-properties-common'
# - to download CMake
dependencies+=' curl'
# - to build CMake
dependencies+=' libssl-dev'
# - for Python
dependencies+=' libbz2-dev liblzma-dev libsqlite3-dev'
# - to download rippled
dependencies+=' git'
# - CMake generators (but not CMake itself)
dependencies+=' make ninja-build'
apt install --yes ${dependencies}

add-apt-repository --yes ppa:ubuntu-toolchain-r/test
apt install --yes gcc-${gcc_version} g++-${gcc_version}

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

curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install 3.10-dev
pyenv global 3.10-dev

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
make --jobs $(nproc)
make install
cd ..
rm --recursive --force ${cmake_slug}

# Install Conan.
pip install --upgrade pip
pip install conan==${conan_version}

conan profile new --detect gcc
conan profile update settings.compiler=gcc gcc
conan profile update settings.compiler.version=${gcc_version} gcc
conan profile update settings.compiler.libcxx=libstdc++11 gcc
conan profile update settings.compiler.cppstd=20 gcc
conan profile update env.CC=/usr/bin/gcc gcc
conan profile update env.CXX=/usr/bin/g++ gcc

# Clean up.
apt clean
