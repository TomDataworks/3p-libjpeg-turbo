#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

LIJPEG_TURBO_VERSION="1.3.1"
LIBJPEG_TURBO_SOURCE_DIR="libjpeg-turbo-$LIJPEG_TURBO_VERSION"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

top="$(pwd)"
stage="$top/stage"
stage_include="$stage/include/jpeglib"
stage_debug="$stage/lib/debug"
stage_release="$stage/lib/release"
mkdir -p "$stage_include"
mkdir -p "$stage_debug"
mkdir -p "$stage_release"
pushd "$LIBJPEG_TURBO_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
		mkdir -p build
		pushd build
		
		cmake -G "Visual Studio 12" ../ -DWITH_JPEG8=ON
		
		build_sln "libjpeg-turbo.sln" "Debug|Win32"
		build_sln "libjpeg-turbo.sln" "Release|Win32"
		
		cp -a "jconfig.h" "$stage_include"
		cp -a "Debug/jpeg-static.lib" "$stage_debug/jpeglib.lib"
		cp -a "Release/jpeg-static.lib" "$stage_release/jpeglib.lib"
		popd

		cp -a *.h "$stage_include"
        ;;
        "windows64")
		mkdir -p build
		pushd build
		
		cmake -G "Visual Studio 12 Win64" ../ -DWITH_JPEG8=ON
		
		build_sln "libjpeg-turbo.sln" "Debug|x64"
		build_sln "libjpeg-turbo.sln" "Release|x64"
		
		cp -a "jconfig.h" "$stage_include"
		cp -a "Debug/jpeg-static.lib" "$stage_debug/jpeglib.lib"
		cp -a "Release/jpeg-static.lib" "$stage_release/jpeglib.lib"
		popd

		cp -a *.h "$stage_include"
        ;;
        "darwin")
        ;;
        "linux")
            JOBS=`cat /proc/cpuinfo | grep processor | wc -l`

            # Let's remain compatible with the LL viewer cmake for less merge hell in the future if it ever changes.
            # and until Windows and Darwin builds are worked out for this thing.
            # Release Build
            CFLAGS="-m32 -O3 -msse -msse2 -mfpmath=sse" CXXFLAGS="$CFLAGS" LDFLAGS="-m32" ./configure --with-jpeg8 \
                    --host i686-pc-linux-gnu --prefix="$stage" --includedir="$stage/include/jpeglib" --libdir="$stage/lib/release"
            make -j$JOBS
            make install

            make clean

            # Debug Build
            CFLAGS="-m32 -O0 -g -msse -msse2 -mfpmath=sse" CXXFLAGS="$CFLAGS" LDFLAGS="-m32" ./configure --with-jpeg8 \
                    --host i686-pc-linux-gnu --prefix="$stage" --includedir="$stage/include/jpeglib" --libdir="$stage/lib/debug"
            make -j$JOBS
            make install
        ;;
        "linux64")
            JOBS=`cat /proc/cpuinfo | grep processor | wc -l`

            # Let's remain compatible with the LL viewer cmake for less merge hell in the future if it ever changes.
            # and until Windows and Darwin builds are worked out for this thing.
            # Release Build
            CFLAGS="-m64 -O3 -msse -msse2 -mfpmath=sse" CXXFLAGS="$CFLAGS" LDFLAGS="-m64" ./configure --with-jpeg8 \
                    --host i686-pc-linux-gnu --prefix="$stage" --includedir="$stage/include/jpeglib" --libdir="$stage/lib/release"
            make -j$JOBS
            make install

            make clean

            # Debug Build
            CFLAGS="-m64 -O0 -g -msse -msse2 -mfpmath=sse" CXXFLAGS="$CFLAGS" LDFLAGS="-m64" ./configure --with-jpeg8 \
                    --host i686-pc-linux-gnu --prefix="$stage" --includedir="$stage/include/jpeglib" --libdir="$stage/lib/debug"
            make -j$JOBS
            make install
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp README "$stage/LICENSES/jpeglib.txt"
popd

pass

