#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

LIJPEG_TURBO_VERSION="1.5.0"
LIBJPEG_TURBO_SOURCE_DIR="libjpeg-turbo"

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

echo "${LIJPEG_TURBO_VERSION}" > "${stage}/VERSION.txt"

pushd "$LIBJPEG_TURBO_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            mkdir -p build
            pushd build
            
            cmake -G "Visual Studio 14" ../ -DCMAKE_SYSTEM_VERSION="10.0.14393.0" -DWITH_JPEG8=ON -DWITH_CRT_DLL=ON
            
            build_sln "libjpeg-turbo.sln" "Debug" "Win32"
            build_sln "libjpeg-turbo.sln" "Release" "Win32"
            
            cp -a "jconfig.h" "$stage_include"
            cp -a "Debug/jpeg-static.lib" "$stage_debug/jpeglib.lib"
            cp -a "Release/jpeg-static.lib" "$stage_release/jpeglib.lib"
            popd

            cp -a *.h "$stage_include"
        ;;
        "windows64")
            mkdir -p build
            pushd build
            
            cmake -G "Visual Studio 14 Win64" ../ -DCMAKE_SYSTEM_VERSION="10.0.14393.0" -DWITH_JPEG8=ON  -DWITH_CRT_DLL=ON
            
            build_sln "libjpeg-turbo.sln" "Debug" "x64"
            build_sln "libjpeg-turbo.sln" "Release" "x64"
            
            cp -a "jconfig.h" "$stage_include"
            cp -a "Debug/jpeg-static.lib" "$stage_debug/jpeglib.lib"
            cp -a "Release/jpeg-static.lib" "$stage_release/jpeglib.lib"
            popd

            cp -a *.h "$stage_include"
        ;;
        "darwin")
            DEVELOPER=$(xcode-select --print-path)
            opts="-mmacosx-version-min=10.8 -DMAC_OS_X_VERSION_MIN_REQUIRED=1080 -iwithsysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk/"
            CFLAGS="-arch x86_64  ${opts}" CXXFLAGs="-arch x86_64 ${opts}" LDFLAGS="-arch x86_64 ${opts}" \
                ./configure --prefix="${stage}64" --includedir="${stage}64/include/jpeglib" --libdir="${stage}64/lib/release" --enable-static --disable-shared --with-jpeg8 --host x86_64-apple-darwin NASM=/opt/local/bin/nasm
            make
            make install
            make clean

            CFLAGS="-i386 ${opts}" CXXFLAGs="-i386 ${opts}" LDFLAGS="-i386 ${opts}" \
                ./configure --prefix="${stage}" --includedir="$stage/include/jpeglib" --libdir="$stage/lib/release" --with-jpeg8 --enable-static --disable-shared --host i686-apple-darwin CFLAGS='-O3 -m32' LDFLAGS=-m32
            make
            make install
            make clean

            for f in "${stage}"/lib/release/*.a ; do
                lipo -create "$f" "${stage}64"/lib/release/$(basename $f) -output "$f"
            done
        ;;
        "linux")
            JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
            HARDENED="-fstack-protector -D_FORTIFY_SOURCE=2"

            # Let's remain compatible with the LL viewer cmake for less merge hell in the future if it ever changes.
            # and until Windows and Darwin builds are worked out for this thing.
            # Debug Build
            CFLAGS="-m32 -Og -g" CXXFLAGS="$CFLAGS -std=c++11" LDFLAGS="-m32" ./configure --with-jpeg8 \
                    --with-pic --prefix="\${AUTOBUILD_PACKAGES_DIR}" --includedir="\${prefix}/include/jpeglib" --libdir="\${prefix}/lib/debug"
            make -j$JOBS
            make install DESTDIR="$stage"

            make distclean

            # Release Build
            CFLAGS="-m32 -O3 -g $HARDENED" CXXFLAGS="$CFLAGS -std=c++11" LDFLAGS="-m32" ./configure --with-jpeg8 \
                    --with-pic --prefix="\${AUTOBUILD_PACKAGES_DIR}" --includedir="\${prefix}/include/jpeglib" --libdir="\${prefix}/lib/release"
            make -j$JOBS
            make install DESTDIR="$stage"

            make distclean
        ;;
        "linux64")
            JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
            HARDENED="-fstack-protector -D_FORTIFY_SOURCE=2"

            # Let's remain compatible with the LL viewer cmake for less merge hell in the future if it ever changes.
            # and until Windows and Darwin builds are worked out for this thing.
            # Debug Build
            CFLAGS="-m64 -Og -g" CXXFLAGS="$CFLAGS -std=c++11" LDFLAGS="-m64" ./configure --with-jpeg8 \
                    --with-pic --prefix="\${AUTOBUILD_PACKAGES_DIR}" --includedir="\${prefix}/include/jpeglib" --libdir="\${prefix}/lib/debug"
            make -j$JOBS
            make install DESTDIR="$stage"

            make distclean

            # Release Build
            CFLAGS="-m64 -O3 -g $HARDENED" CXXFLAGS="$CFLAGS -std=c++11" LDFLAGS="-m64" ./configure --with-jpeg8 \
                    --with-pic --prefix="\${AUTOBUILD_PACKAGES_DIR}" --includedir="\${prefix}/include/jpeglib" --libdir="\${prefix}/lib/release"
            make -j$JOBS
            make install DESTDIR="$stage"

            make distclean
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp LICENSE.md "$stage/LICENSES/jpeglib.txt"
popd

pass

