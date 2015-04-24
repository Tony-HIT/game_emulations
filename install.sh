#!/bin/bash

project_dir="game_emulations"
cur_dir=$(cd `dirname $0`; pwd)
FILE_udev="50-mali.rules"
FILE_fb="99-fbturbo.conf"

function write_udev_rules {
  echo -e "KERNEL==\"mali\", MODE=\"0660\", GROUP=\"video\"" > $FILE_udev
  echo -e "KERNEL==\"ump\", MODE=\"0660\", GROUP=\"video\"" >> $FILE_udev
  echo -e "KERNEL==\"disp\", MODE=\"0660\", GROUP=\"video\"" >> $FILE_udev
  echo -e "KERNEL==\"g2d\", MODE=\"0660\", GROUP=\"video\"" >> $FILE_udev
  echo -e "KERNEL==\"fb*\", MODE=\"0660\", GROUP=\"video\"" >> $FILE_udev
  echo -e "KERNEL==\"cedar_dev\", MODE=\"0660\", GROUP=\"video\"" >> $FILE_udev
  sudo cp $FILE_udev /etc/udev/rules.d/
}

function install_packages {
  echo "Install some essensial packages...."
  sudo apt-get update
  sudo apt-get install git build-essential make gcc autoconf libtool debhelper \
  dh-autoreconf pkg-config automake xutils-dev libx11-dev libxext-dev libdrm-dev \
  x11proto-dri2-dev libxfixes-dev xorg-dev libltdl-dev mesa-utils

}

function git_repo {
  if [ -d "/$HOME/$project_dir/libdri2" ];then
     echo "libdri2 already exists"
  else
    git_repo_libdri2
  fi

  if [ -d "/$HOME/$project_dir/libump" ];then
     echo "libump already exists"
  else
    git_repo_libump
  fi

  if [ -d "/$HOME/$project_dir/sunxi-mali" ];then
     echo "sunxi-mali already exists"
  else
    git_repo_sunxi_mali
  fi

  if [ -d "/$HOME/$project_dir/xf86-video-fbturbo" ];then
     echo "fbturbo already exists"
  else
    git_repo_fbturbo
  fi
}

function git_repo_libdri2 {
  echo "Download the libdri2 git repository..."
  git clone https://github.com/robclark/libdri2.git
}

function git_repo_libump {
  echo "Download the libump git repository..."
  git clone https://github.com/linux-sunxi/libump.git
}

function git_repo_sunxi_mali {
  echo "Download the sunxi_mali git repository..."
  git clone https://github.com/linux-sunxi/sunxi-mali.git
}

function git_repo_fbturbo {
  echo "Download the fbturbo git repository..."
  git clone https://github.com/ssvb/xf86-video-fbturbo.git
}


function build_libdri2 {
  echo "build libdri2 ..."
  ./autogen.sh
  ./configure --prefix=/usr
  make
  sudo make install
  sudo ldconfig
}

function build_libump {
  echo "build libump ..."
#  autoreconf -i
#  ./configure
#  make
#  make install
  dpkg-buildpackage -b
  sudo dpkg -i ../libump_3.0-0sunxi1_armhf.deb
  sudo dpkg -i ../libump-dev_3.0-0sunxi1_armhf.deb
  
}

function build_sunxi_mali {
  echo "build sunxi_mali ..."
  git submodule init
  git submodule update

  if [ -f "$cur_dir/patch/gl2.h" ];then
    cp $cur_dir/patch/gl2.h ./include/GLES2/
  else
    echo "Please download the gl2.h file and put it in $0 "
  fi

  if [ -f "$cur_dir/patch/gl2ext.h" ];then
    cp $cur_dir/patch/gl2ext.h ./include/GLES2/
  else
    echo "Please download the gl2ext.h file and put it in $0 "
  fi
  make config
#  make config ABI=armhf VERSION=r3p0 EGL_TYPE=framebuffer
  sudo make install
#  sudo make -C include install
#  sudo mkdir /usr/lib/mali
#  sudo make -C lib/mali prefix=/usr libdir='$(prefix)/lib/mali/' install
#  sudo sh -c 'echo "/usr/lib/mali" > /etc/ld.so.conf.d/mali.conf'
}

function build_fbturbo {
  echo "build fbturbo driver ..."
  autoreconf -v -i
  ./configure --prefix=/usr
  make
  sudo make install
  echo -e "Section \"Screen\"" > $FILE_fb
  echo -e "\tIdentifier      \"My Screen\"" >> $FILE_fb
  echo -e "\tDevice          \"Allwinner A10/A13 FBDEV\"" >> $FILE_fb
  echo -e "\tMonitor         \"My Monitor\"" >> $FILE_fb
  echo -e "EndSection" >> $FILE_fb
  echo -e "\nSection \"Device\"" >> $FILE_fb
  echo -e "\tIdentifier      \"Allwinner A10/A13 FBDEV\"" >> $FILE_fb
  echo -e "\tDriver           \"fbturbo\"" >> $FILE_fb
  echo -e "\tOption          \"fbdev\" \"/dev/fb0\"" >> $FILE_fb
  echo -e "\tOption          \"SwapbuffersWait\" \"true\"" >> $FILE_fb
  echo -e "\tOption          \"AccelMethod\" \"G2D\"" >> $FILE_fb
  echo -e "EndSection" >> $FILE_fb
  echo -e "\nSection \"Monitor\"" >> $FILE_fb
  echo -e "\tIdentifier      \"My Monitor\"" >> $FILE_fb
  echo -e "\tOption          \"DPMS\" \"false\"" >> $FILE_fb
  echo -e "EndSection" >> $FILE_fb
  if [ ! -d "/etc/X11/xorg.conf.d/" ];then
    sudo mkdir -p /etc/X11/xorg.conf.d
  fi
  sudo cp $FILE_fb /etc/X11/xorg.conf.d/99-fbturbo.conf
}

install_packages
cd $HOME
if [ -d "/$HOME/$project_dir" ];then
  echo "$DIR already exist!"
  cd $project_dir
else
  mkdir $HOME/$project_dir
  cd $project_dir
fi

git_repo

if [ -d "./libdri2" ];then
  cd libdri2
  build_libdri2
else
  echo "Please download libdri2"
fi

cd $HOME/$project_dir

if [ -d "./libump" ];then
  cd libump
  build_libump
else
  echo "Please download libump"
fi

cd $HOME/project_dir

if [ -d "./sunxi-mali" ];then
  cd sunxi-mali
  build_sunxi_mali
else
  echo "Please download libump"
fi

cd $HOME/$project_dir

if [ -d "./xf86-video-fbturbo" ];then
  cd xf86-video-fbturbo
  build_fbturbo
else
  echo "Please download libump"
fi
  
write_udev_rules

