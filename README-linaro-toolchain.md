# Build instructions for Cross Compilation
------------------------------------------

## Requirements:

* Using Raspbian Linux Operating system libraries.
* Raspberry Pi board.
* Using Linaro ARM toolchain or
* Using https://github.com/raspberrypi/tools.git ARM toolchain.
* Cross compilation is tested using Ubuntu 16.04 LTS.

## Installing Linaro toolchain & Raspbian libraries:

The 'install-linaro-toolchain.sh' script will also install a subset of Raspbian root filesystem for cross compiling libzwaveip project only.
The Linaro toolchain installation directory (/opt/linaro) and cross compiler gcc version are both hard-code in these 2 files:
* cmake/linaro-toolchain.cmake
* scripts/install-linaro-toolchain.sh

```bash
$ sudo ./scripts/install-linaro-toolchain.sh
```

## To compile:

```bash
$ mkdir build
$ cd build
$ cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/linaro-toolchain.cmake ..
$ make
```
