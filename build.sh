#!/bin/bash
set -e

cd "${0%/*}"
mkdir -p bin
nasm bootloader.asm -f bin -o bin/boot.img
nasm kernel.asm -f bin -o bin/kernel.img -i./includes
cat bin/boot.img bin/kernel.img > bin/pongos.img

