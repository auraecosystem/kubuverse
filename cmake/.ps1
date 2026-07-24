# Configure
cmake -S . -B build -G "Visual Studio 17 2022" -A x64

# Build Release
cmake --build build --config Release

# Build Debug
cmake --build build --config Debug

# Run
cmake --build build --config Release --target run

# Install
cmake --install build --config Release --prefix build/install

# Package
cmake --build build --config Release --target package
