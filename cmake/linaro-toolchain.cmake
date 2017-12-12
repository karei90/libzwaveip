# Specify System Name to enable cross compiling.
set(CMAKE_SYSTEM_NAME Linux)

# Specify the CPU CMake is building for.
set(CMAKE_SYSTEM_PROCESSOR arm)

# Set root directory for libraries and headers. Path will pass to the compiler --sysroot flag.
set(CMAKE_SYSROOT /opt/linaro/raspbian_rootfs)

# Prepend path in case make install is invoked during the build process.
set(CMAKE_STAGING_PREFIX $ENV{HOME}/tmp/staging/rootfs)
set(CMAKE_INSTALL_PREFIX $ENV{HOME}/tmp/staging/rootfs)

# Specify the cross compiler.
# Note: ${tools} is a symbolic link to the actual compiler (32 or 64bit, gcc version) directory.
set(tools /opt/linaro/gcc-linaro-arm-linux-gnueabihf)
set(CMAKE_C_COMPILER ${tools}/bin/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER ${tools}/bin/arm-linux-gnueabihf-g++)
set(CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf)

# Specifically set Compiler and Linker flags for Multiarch libraries and headers.
set(CMAKE_C_FLAGS "-I${CMAKE_SYSROOT}/usr/include/${CMAKE_LIBRARY_ARCHITECTURE}" CACHE STRING "" FORCE)
set(CMAKE_C_LINK_FLAGS "-Wl,-rpath-link=${CMAKE_SYSROOT}/lib/${CMAKE_LIBRARY_ARCHITECTURE} -Wl,-rpath-link=${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}" CACHE STRING "" FORCE)

# Specify path for CMake to search when invoke find_package(), find_library(), find_path() functions.
set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")

# NEVER allow CMake to search/run programs (ARM executable) from the sysroot directories.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# ONLY allow CMake to search for libraries and headers in the sysroot directories.
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
