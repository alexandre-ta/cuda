#! /bin/bash

export PATH=~/.bin/:$PATH

if [ ! -d ~/.bin/ ]; then
    mkdir ~/.bin/

fi
rm ~/.bin/*
ln -s /usr/bin/gcc-4.7 ~/.bin/gcc
ln -s /usr/bin/g++-4.7 ~/.bin/g++
