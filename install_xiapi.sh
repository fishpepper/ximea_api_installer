#!/bin/bash
function check(){
    if [ $? == 0 ]; then
        echo "OK"
    else
        echo "ERROR: previous command failed. will exit now!"
        exit 1
    fi
}

PREFIX=$1
optpath=$PREFIX/opt/XIMEA

echo "will install ximea api to prefix $PREFIX/"

rm -rf package*
#wget http://www.ximea.com/downloads/recent/XIMEA_Linux_SP.tgz
check

tar xzf XIMEA_Linux_SP.tgz && cd package
check

arch=$(uname -m)
if [ "$arch" == "i686" ]; then
        echo Instaling x32 bit version
	platform_bits=32
	this_is_x32=1
elif [ "$arch" == "x86_64" ]; then
	platform_bits=64
        this_is_x64=1
        echo Instaling x64 bit version
fi
KV=$(uname -r).

mkdir -p $PREFIX/bin $PREFIX/lib/pkgconfig $PREFIX/usr/lib $PREFIX/usr/include $optpath $optpath/bin $optpath/lib 2>/dev/null
cp version_LINUX_SP.txt $optpath
check

#create pkg config
VERSION_REL=`cat version_LINUX_SP.txt |cut -d "_"  -f 3|cut -d "V" -f 2`
VERSION_MAJOR=`cat version_LINUX_SP.txt |cut -d "_"  -f 4 | sed 's/^0*//'`
VERSION_MINOR=`cat version_LINUX_SP.txt |cut -d "_"  -f 5 | sed 's/^0*//'`

echo -ne "prefix=$PREFIX\nexec_prefix=\${prefix}\nlibdir=\nincludedir=\${prefix}/usr/include/\n\nName: xiapi\nDescription: ximea api\nVersion: $VERSION_REL.$VERSION_MAJOR.$VERSION_MINOR\nLibs:  \${exec_prefix}/lib/m3api.so\nCflags: -I\${includedir}\n" > $PREFIX/lib/pkgconfig/xiapi.pc
check



echo "installing libusb (ximea version)"
cp -d libs/libusb/vanillaX$platform_bits/lib* $PREFIX/lib/
check

if [ "${KV:0:$(($(expr index $KV .)-1))}" -eq 3 ] && ( \
        [ "${KV:$(expr index $KV .):$(($(expr index ${KV:$(expr index $KV .)} .)-1))}" -eq 12 ] || \
        [ "${KV:$(expr index $KV .):$(($(expr index ${KV:$(expr index $KV .)} .)-1))}" -eq 13 ] )
then
        echo "-------------------------------------"
        echo "Adding USB3 support workaround for kernels 3.12 - 3.13 to $optpath/config.ini."
        echo "It is advised to avoid these two kernel versions."
        echo "-------------------------------------"

        echo "; workaround for kernels 3.12 & 3.13"     >> $optpath/config.ini
        echo "[softhard\\mm40api]"                      >> $optpath/config.ini
        echo "PPTB = 1008"                              >> $optpath/config.ini
        echo                                            >> $optpath/config.ini
fi

echo "installing API "

cp api/X$platform_bits/libm3api.so $PREFIX/lib/libm3api.so.0.0.0 && \
ln -snf libm3api.so.0.0.0 $PREFIX/lib/libm3api.so.0 && \
ln -snf libm3api.so.0.0.0 $PREFIX/lib/libm3api.so
check

cp -R include $optpath/ && \
cp -R examples $optpath/
check

ln -snf $optpath/include $PREFIX/usr/include/m3api
check

#echo
#echo Rebuilding linker cache
#echo /lib > /etc/ld.so.conf.d/000XIMEA.conf
#echo /usr/lib >> /etc/ld.so.conf.d/000XIMEA.conf
#ldconfig


echo "installing XIMEA-GenTL library"
cp libs/gentl/X$platform_bits/libXIMEA_GenTL.* $optpath/lib/
check

echo "installing xiSample"
cp bin/xiSample.$platform_bits $optpath/bin/xiSample
check

echo "installing vaViewer"
cp bin/vaViewer.$platform_bits $optpath/bin/vaViewer
check

echo "installing streamViewer"
cp bin/streamViewer.$platform_bits $optpath/bin/streamViewer
check

echo "done"
