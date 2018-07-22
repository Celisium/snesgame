#!/bin/sh
wla-65816 -o main.o main.asm
wlalink -v -r link.link main.sfc
rm main.o
