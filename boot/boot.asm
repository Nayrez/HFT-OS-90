; =====================================
; HFT X-Boot 0.4 - Stage 1 Bootloader
; Автор: Nayrez / HFT
; =====================================

[org 0x7C00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Сохраняем номер диска
    mov [BOOT_DRIVE], dl

    ; Очистка экрана и вывод баннера
    mov ax, 0x0003
    int 0x10
    mov si, banner
    call print_string

    ; Загрузка второй ступени
    mov ax, STAGE2_SEG
    mov es, ax
    xor bx, bx
    mov cx, STAGE2_SECTORS
    call load_stage2

    ; Проверка успешной загрузки
    jc stage2_error

    ; Переход ко второй ступени
    mov si, success_msg
    call print_string
    jmp STAGE2_SEG:0x0000

; Загрузка второй ступени (CHS)
load_stage2:
    mov di, 3 ; Попытки
.retry:
    pusha
    mov ah, 0x02
    mov al, STAGE2_SECTORS
    mov ch, 0x00        ; Цилиндр 0
    mov cl, STAGE2_LBA  ; Сектор 2 (LBA 1 = CHS 0,0,2)
    mov dh, 0x00        ; Головка 0
    mov dl, [BOOT_DRIVE]
    int 0x13
    popa
    jnc .success
    dec di
    jnz .retry
    stc
    ret
.success:
    clc
    ret

; Процедура вывода строки
print_string:
    mov ah, 0x0E
.next:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

; Обработчики ошибок
stage2_error:
    mov si, errmsg
    call print_string
    mov si, retry_msg
    call print_string
    call wait_key
    jmp 0xFFFF:0x0000  ; Перезагрузка

; Ожидание клавиши
wait_key:
    xor ah, ah
    int 0x16
    ret

; Данные
banner      db 0x0D, 0x0A, "HFT X-Boot 0.4 Stage 1", 0x0D, 0x0A, 0
success_msg db "Loading Stage 2...", 0x0D, 0x0A, 0
errmsg      db "Stage2 load error! ", 0
retry_msg   db "Press any key to reboot...", 0

BOOT_DRIVE db 0

; Константы
STAGE2_SEG    equ 0x07E0   ; 0x07E0:0x0000 = 0x7E00 (после boot sector)
STAGE2_LBA    equ 0x02     ; Сектор 2 (LBA)
STAGE2_SECTORS equ 4       ; 4 сектора = 2KB

times 510-($-$$) db 0
dw 0xAA55
