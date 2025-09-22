; =====================================
; HFT X-Boot 0.4 - Stage 2 Bootloader
; =====================================

[org 0x7E00]
[bits 16]

start:
    ; Инициализация
    mov ax, 0x0000
    mov ds, ax
    mov es, ax

    ; Сохраняем номер диска из stage1
    mov [BOOT_DRIVE], dl

    ; Вывод информации
    mov si, banner
    call print_string

    ; Проверка оборудования
    call check_system

    ; Загрузка ядра
    call load_kernel
    jc .error

    ; Запуск ядра
    mov si, success_msg
    call print_string
    jmp KERNEL_LOAD_SEG:KERNEL_HDR_SIZE

.error:
    mov si, error_msg
    call print_string
    call reboot_prompt

; Проверка системы
check_system:
    ; Проверка расширений LBA
    call check_lba_extensions

    ; Проверка памяти
    call check_memory

    ; Проверка VGA
    call check_video
    ret

; Проверка памяти
check_memory:
    ; Получение базовой памяти
    int 0x12
    mov [base_memory], ax

    ; Попытка получить расширенную память
    mov ax, 0xE801
    int 0x15
    jc .no_ext_memory
    mov [ext_memory], ax
.no_ext_memory:
    ret

; Проверка видео
check_video:
    ; Проверка VGA
    mov ax, 0x1A00
    int 0x10
    cmp al, 0x1A
    jne .no_vga
    mov byte [has_vga], 1
.no_vga:
    ret

; Загрузка ядра
load_kernel:
    ; Загрузка заголовка ядра
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    xor bx, bx
    mov eax, KERNEL_LBA
    mov cx, 1
    call read_sectors
    jc .error

    ; Проверка сигнатуры ядра
    cmp word [es:0], 0x4648  ; 'HF'
    jne .bad_header
    cmp word [es:2], 0x4B54  ; 'TK'
    jne .bad_header

    ; Получение размера ядра
    mov ax, [es:4]          ; Размер в секторах
    cmp ax, 1
    jbe .bad_header
    cmp ax, MAX_SECTORS
    ja .too_big

    ; Загрузка остальных секторов
    mov cx, ax
    dec cx
    jz .done
    mov eax, KERNEL_LBA
    inc eax
    mov bx, 512
    call read_sectors
    jc .error

.done:
    clc
    ret

.error:
    mov si, disk_error_msg
    call print_string
    stc
    ret

.bad_header:
    mov si, bad_header_msg
    call print_string
    stc
    ret

.too_big:
    mov si, too_big_msg
    call print_string
    stc
    ret

; Запрос перезагрузки
reboot_prompt:
    mov si, reboot_msg
    call print_string
    call wait_key
    jmp warm_reboot

; Теплая перезагрузка
warm_reboot:
    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000
    jmp 0xFFFF:0x0000

; Ожидание клавиши
wait_key:
    xor ah, ah
    int 0x16
    ret

; Процедура вывода строки
print_string:
    mov ah, 0x0E
.next_char:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next_char
.done:
    ret

; Включаем модуль диска
%include "disk.inc"

; Данные
banner           db 0x0D, 0x0A, "HFT X-Boot 0.4 Stage 2", 0x0D, 0x0A, 0
success_msg      db "Kernel loaded successfully!", 0x0D, 0x0A, 0
error_msg        db "Boot failed!", 0x0D, 0x0A, 0
disk_error_msg   db "Disk error!", 0x0D, 0x0A, 0
bad_header_msg   db "Invalid kernel!", 0x0D, 0x0A, 0
too_big_msg      db "Kernel too big!", 0x0D, 0x0A, 0
reboot_msg       db "Press any key to reboot...", 0x0D, 0x0A, 0

; Системная информация
base_memory      dw 0
ext_memory       dw 0
has_vga          db 0
BOOT_DRIVE       db 0

; Константы
KERNEL_LOAD_SEG  equ 0x1000
KERNEL_LBA       equ 0x06    ; После stage2 (LBA 2-5)
KERNEL_HDR_SIZE  equ 0x0200
MAX_SECTORS      equ 512     ; 256KB макс размер ядра

; Заполнитель чтобы файл не был пустым
times 1024-($-$$) db 0
