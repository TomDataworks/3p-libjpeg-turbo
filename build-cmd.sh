#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

LIJPEG_TURBO_VERSION="1.2.0"
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
pushd "$LIBJPEG_TURBO_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
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

