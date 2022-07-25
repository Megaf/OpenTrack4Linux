###########################################
##           OpenTrack4Linux             ##
###########################################
#                                         #
# OpenTrack4Linux Version 0.1.24072022    #
# Created on 24/07/2022                   #
#                                         #
# Author: Megaf - mmegaf[at]gmail[dot]com #
#                                         #
# Description: This script will try to    #
# download the source code of OpenTrack   #
# compile it and add Aruco support.       #
#                                         #
###########################################

#!/bin/bash

branch="master"
install_dir="/usr/local"
compiler_flags="-O3 -pipe -march=native -mtune=native -flto"
debian_dependencies="build-essential cmake git qttools5-dev qtbase5-private-dev libprocps-dev libopencv-dev ccache svn"
addons_dir="$HOME/Downloads/FlightGear_Addons"
headtracker_dir="$addons_dir/Headtracker"
headtracker_url="http://svn.code.sf.net/p/flightgear/fgaddon/trunk/Addons/Headtracker"

export CFLAGS="$compiler_flags"
export CXXFLAGS="$compiler_flags"

install_debian_dependencies()
{
  sudo apt install -y $debian_dependencies
}

download()
{
  if [ -d "$download_dir" ];
    then
      echo "##>> $thing was already downloaded, updating it if needed."
      cd "$download_dir" && git pull
    else
      echo "##>> $thing was not found, downloading it now."
      git clone --depth=1 --single-branch -b "$branch" "$git_repo" "$download_dir"
  fi
}

compile()
{
  echo "##>> Creating $compiler_dir"
  mkdir -p "$compile_dir"
  cd "$compile_dir"
  echo "##>> Running cmake"
  cmake "$download_dir" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="$compiler_flags" \
  -DCMAKE_CXX_FLAGS="$compiler_flags" -DCMAKE_INSTALL_PREFIX="$install_dir" $aruco
  echo "##>> Compiling"
  make -j $(nproc)
}

install_()
{
  echo "##>> Please enter your user password so we can install OpenTrack to $install_dir"
  sudo make install  
}

install_addon()
{
  mkdir -p "$addons_dir"
  if [ -d "$headtracker_dir" ];
    then
      echo "##>> Headtracker addon already downloaded, updating it if needed."
      cd "$addons_dir" && svn cleanup Headtracker && cd "$headtracker_dir" && svn update
    else
      echo "##>> Headtracker addon no found, downloading it."
      cd "$addons_dir"
      svn co "$headtracker_url"
  fi
}

# Install required dependencies
install_debian_dependencies

# Download and build aruco
thing="aruco"
echo "##>> Downloading and compiling $thing"
git_repo="https://github.com/opentrack/$thing"
download_dir="/tmp/$thing-source"
compile_dir="/tmp/$thing-build"
download
compile

# Download and build opentrack
thing="opentrack"
echo "##>> Downloading and compiling $thing"
git_repo="https://github.com/opentrack/$thing"
download_dir="/tmp/$thing-source"
compile_dir="/tmp/$thing-build"
aruco="-DSDK_ARUCO_LIBPATH=/tmp/aruco-build/src/libaruco.a"
download
compile
install_

# Install Headtracker addon
install_addon
echo "##>> Headtracker addon is installed to $headtracker_dir"
echo "##>> To use enable the Headtracker addon, enable it on FlightGear."
echo "##>> For example."
echo "##>> --addon=$headtracker_dir --generic=socket,in,120,127.0.0.1,5542,udp,opentrack"
