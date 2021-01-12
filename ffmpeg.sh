#!/usr/bin/env bash

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "compile and install ffmpeg"
echo "------------------------------------------------------------------------------"
cd /opt/

if [[ ! -d "ffmpeg-build" ]]; then
    git clone https://github.com/jb-alvarado/compile-ffmpeg-osx-linux.git ffmpeg-build
    cd ffmpeg-build
else
    cd ffmpeg-build
    git pull

    rm -rf build local
fi

if [[ ! -f "build_config.txt" ]]; then
cat <<EOF > "build_config.txt"
#--enable-decklink
--disable-ffplay
--disable-sdl2
--enable-fontconfig
#--enable-libaom
#--enable-libass
#--enable-libbluray
--enable-libfdk-aac
--enable-libfribidi
--enable-libfreetype
--enable-libmp3lame
--enable-libopus
--enable-libsoxr
--enable-libsrt
--enable-libtwolame
--enable-libvpx
--enable-libx264
--enable-libx265
--enable-libzimg
--enable-libzmq
--enable-nonfree
#--enable-opencl
#--enable-opengl
#--enable-openssl
#--enable-libsvtav1
EOF
    sed -i 's/mediainfo="yes"/mediainfo="no"/g' ./compile-ffmpeg.sh
    sed -i 's/mp4box="yes"/mp4box="no"/g' ./compile-ffmpeg.sh
fi

./compile-ffmpeg.sh

cp local/bin/ff* /usr/local/bin/
