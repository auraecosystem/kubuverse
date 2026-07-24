# Debug
flutter build windows --debug

# Release
flutter build windows --release

# Profile
flutter build windows --profile
cmake -S . -B build -G "Visual Studio 17 2022" -A x64

cmake --build build --config Release
cmake -S . -B build -DENABLE_CPACK=ON

cmake --build build --config Release

cpack --config build/CPackConfig.cmake
