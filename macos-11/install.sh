brew update
brew install cmake
# `softwareupdate` cannot seem to find any updates, not for Xcode or anything,
# so use Homebrew to update Clang to a version (>=13.1.6) that can build rippled.
brew install llvm

cc=/usr/local/opt/llvm/bin/clang
cxx=/usr/local/opt/llvm/bin/clang++
ldflags='-L/usr/local/opt/llvm/lib/c++ -Wl,-rpath,/usr/local/opt/llvm/lib/c++'

pip3 install --upgrade pip
pip3 install 'conan<2'

conan profile new default --detect
conan profile update settings.compiler=clang default
conan profile update settings.compiler.version=16 default
conan profile update settings.compiler.cppstd=20 default
conan profile update "conf.tools.build:compiler_executables={'c': '${cc}', 'cpp': '${cxx}'}" default
conan profile update 'options.b2:use_cxx_env=True' default
conan profile update env.CC=${cc} default
conan profile update env.CXX=${cxx} default

conan profile update 'options.boost:extra_b2_flags="define=BOOST_ASIO_HAS_STD_INVOKE_RESULT define=BOOST_NO_CXX98_FUNCTION_BASE"' default
conan profile update 'env.CXXFLAGS="-DBOOST_ASIO_HAS_STD_INVOKE_RESULT -DBOOST_NO_CXX98_FUNCTION_BASE -Wno-error=enum-constexpr-conversion"' default
conan profile update 'conf.tools.build:cxxflags=["-DBOOST_ASIO_HAS_STD_INVOKE_RESULT", "-DBOOST_NO_CXX98_FUNCTION_BASE", "-Wno-error=enum-constexpr-conversion"]' default

# These settings are not necessary for static builds,
# which is all we're doing for now,
# but we can leave them commented here in case they are needed later.
function() {
conan profile update "env.LDFLAGS=${ldflags}" default
# Conan does not have tools.build:ldflags.
linkflags=$(echo ${ldflags} | sed -E 's/[[:space:]]+/", "/g')
conan profile update "conf.tools.build:sharedlinkflags=['${linkflags}']"
conan profile update "conf.tools.build:exelinkflags=['${linkflags}']"
}

dir=$(mktemp --directory)
pushd ${dir}
git clone https://github.com/XRPLF/rippled.git --branch develop --depth 1 .
conan export external/snappy snappy/1.1.9@
conan install . --build --settings build_type=Release
conan install . --build --settings build_type=Debug
popd
rm -rf ${dir}

conan --version
cmake --version
clang --version
