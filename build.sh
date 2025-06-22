#!/usr/bin/env bash
set -euxo pipefail

rgbasm -Wall -Wextra -o hello.o hello.asm

rgblink --dmg --tiny  --wramx -n hello.sym -o hello.gb hello.o

cp hello.gb hello-unfixed.gb
rgbfix hello.gb
