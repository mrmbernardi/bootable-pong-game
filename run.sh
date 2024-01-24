#!/bin/bash

cd "${0%/*}"
qemu-system-i386 -drive file=bin/pongos.img,index=0,if=floppy,format=raw
