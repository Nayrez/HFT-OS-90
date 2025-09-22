; =====================================
; HFT X-Boot - Disk I/O Module
; =====================================

; Проверка расширений LBA
check_lba_extensions:
mov ah, 0x41
mov bx, 0x55AA
mov dl, [BOOT_DRIVE]
int 0x13
jc .no_lba
cmp bx, 0xAA55
jne .no_lba
test cl, 1
jz .no_lba
mov byte [LBA_AVAILABLE], 1
ret
.no_lba:
mov byte [LBA_AVAILABLE], 0
ret

; Чтение секторов
read_sectors:
cmp byte [LBA_AVAILABLE], 1
je .lba_read
jmp .chs_read

; LBA чтение
.lba_read:
pushad
mov di, 5
.retry_lba:
mov dword [DAP_LBA], eax
mov word [DAP_OFFSET], bx
mov word [DAP_SEGMENT], es
mov byte [DAP_COUNT], cl

mov si, DAP
mov ah, 0x42
mov dl, [BOOT_DRIVE]
int 0x13
jnc .success

dec di
jz .error
call reset_disk
jmp .retry_lba

; CHS чтение
.chs_read:
pushad
mov di, 5
.retry_chs:
push cx
push eax

; Конвертация LBA в CHS
xor dx, dx
div word [SECTORS_PER_TRACK]
inc dl
mov cl, dl

xor dx, dx
div word [HEADS_PER_CYLINDER]
mov dh, dl
mov ch, al

mov dl, [BOOT_DRIVE]
mov ax, 0x0201

int 0x13
jnc .success_chs

pop eax
pop cx
dec di
jz .error
call reset_disk
jmp .retry_chs

.success_chs:
pop eax
pop cx
.success:
popad
clc
ret

.error:
popad
stc
ret

; Сброс диска
reset_disk:
push ax
mov ah, 0x00
mov dl, [BOOT_DRIVE]
int 0x13
pop ax
ret

; Структура DAP
DAP:
db 0x10
db 0
DAP_COUNT:
dw 0
DAP_OFFSET:
dw 0
DAP_SEGMENT:
dw 0
DAP_LBA:
dd 0
dd 0

; Параметры диска
SECTORS_PER_TRACK dw 18
HEADS_PER_CYLINDER dw 2
LBA_AVAILABLE db 0
; BOOT_DRIVE db 0  ; УБИРАЕМ ЭТУ СТРОКУ - определение уже есть в stage2.asm
