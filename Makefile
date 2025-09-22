# Makefile for HFT OS 90 v0.4

NASM = nasm
NASMFLAGS = -f bin
DD = dd
QEMU = qemu-system-x86_64

BOOT_DIR = boot
KERNEL_DIR = kernel
BUILD_DIR = build

BOOT_SRC = $(BOOT_DIR)/boot.asm
STAGE2_SRC = $(BOOT_DIR)/stage2.asm
DISK_INC = $(BOOT_DIR)/disk.inc
KERNEL_SRC = $(KERNEL_DIR)/kernel.asm

BOOT_OUT = $(BUILD_DIR)/boot.bin
STAGE2_OUT = $(BUILD_DIR)/stage2.bin
KERNEL_OUT = $(BUILD_DIR)/kernel.bin
DISK_IMG = $(BUILD_DIR)/disk.img

$(shell mkdir -p $(BUILD_DIR))

all: $(DISK_IMG)

$(BOOT_OUT): $(BOOT_SRC)
	$(NASM) $(NASMFLAGS) -I $(BOOT_DIR) $< -o $@

$(STAGE2_OUT): $(STAGE2_SRC) $(DISK_INC)
	$(NASM) $(NASMFLAGS) -I $(BOOT_DIR) $< -o $@

$(KERNEL_OUT): $(KERNEL_SRC)
	$(NASM) $(NASMFLAGS) -I $(KERNEL_DIR) $< -o $@

$(DISK_IMG): $(BOOT_OUT) $(STAGE2_OUT) $(KERNEL_OUT)
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=$(BOOT_OUT) of=$@ bs=512 conv=notrunc
	$(DD) if=$(STAGE2_OUT) of=$@ bs=512 seek=2 conv=notrunc
	$(DD) if=$(KERNEL_OUT) of=$@ bs=512 seek=6 conv=notrunc

clean:
	rm -rf $(BUILD_DIR)

qemu: $(DISK_IMG)
	$(QEMU) -drive format=raw,file=$< -m 16M

debug: $(DISK_IMG)
	$(QEMU) -drive format=raw,file=$< -s -S -m 16M &

info:
	@echo "Bootloader: $$(stat -c%s $(BOOT_OUT)) bytes"
	@echo "Stage2: $$(stat -c%s $(STAGE2_OUT)) bytes"
	@echo "Kernel: $$(stat -c%s $(KERNEL_OUT)) bytes"

.PHONY: all clean qemu debug info
