# HFT-OS-90
https://img.shields.io/badge/Version-0.4-blue
https://img.shields.io/badge/Build-Passing-green
https://img.shields.io/badge/License-MIT-yellow

A modern operating system for x86 architecture, written from scratch in Assembly and C

HFT OS 90 is an experimental operating system!

🚀 Features

-Two-stage bootloader (HFT X-Boot 0.4) with LBA/CHS support

-Multitasking kernel in x86 real mode

-Interactive command shell with basic commands

-Device drivers: keyboard, VGA, disk drives

-File system support (in development)

-Modular architecture for easy expansion

# Building the Project

# Clone the repository
git clone https://github.com/yourusername/hft-os-90.git
cd hft-os-90

# Build the entire system
make

# Run in QEMU
make qemu

# Build with debug information
make debug


# Running on Real Hardware (CAUTION!)
bash

# Write to USB drive
make usb DEVICE=/dev/sdX

# Write to floppy disk (if you have a floppy drive)
sudo dd if=build/disk.img of=/dev/fd0
