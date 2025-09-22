; =====================================
; HFT OS 90 Kernel 0.2
; Автор: Nayrez / HFT
; =====================================

[org 0x1000*16 + 0x200] ; Сегмент 0x1000, смещение 0x200

[bits 16]

start:
    cli

    ; Установка сегментов данных
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Установка стека
    mov ax, 0x7000
    mov ss, ax
    mov sp, 0xFFFF

    sti

    ; Очистка экрана
    mov ax, 0x0003
    int 0x10

    ; Вывод приветственного сообщения
    mov si, welcome_msg
    call print_string

    ; Вывод информации о системе
    mov si, system_info
    call print_string

    ; Проверка процессора
    call check_cpu

    ; Проверка памяти
    call check_memory

    ; Переход в защищенный режим (в будущих версиях)
    mov si, pmode_msg
    call print_string

    ; Основной цикл
.main_loop:
    mov si, prompt
    call print_string

    ; Ожидание ввода
    call wait_key

    ; Обработка команд
    cmp al, 'h'
    je .show_help
    cmp al, 'r'
    je .reboot
    cmp al, 'm'
    je .show_memory
    cmp al, 'c'
    je .show_cpu
    cmp al, 0x1B ; ESC
    je .halt

    mov si, unknown_cmd
    call print_string
    jmp .main_loop

.show_help:
    mov si, help_msg
    call print_string
    jmp .main_loop

.reboot:
    mov si, reboot_msg
    call print_string
    jmp warm_reboot

.show_memory:
    mov si, memory_info
    call print_string
    jmp .main_loop

.show_cpu:
    mov si, cpu_info
    call print_string
    jmp .main_loop

.halt:
    mov si, halt_msg
    call print_string
    jmp halt_system

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

; Ожидание нажатия клавиши
wait_key:
    xor ah, ah
    int 0x16
    ret

; Проверка процессора
check_cpu:
    pushfd
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 0x00200000
    push eax
    popfd
    pushfd
    pop eax
    xor eax, ecx
    jz .no_cpuid
    mov byte [has_cpuid], 1
.no_cpuid:
    popfd
    ret

; Проверка памяти (базовая)
check_memory:
    ; Используем BIOS функцию для получения объема памяти
    int 0x12
    mov [base_memory_kb], ax
    ret

; Теплая перезагрузка
warm_reboot:
    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000
    jmp 0xFFFF:0x0000

; Завершение работы
halt_system:
    cli
    hlt
    jmp halt_system

; Данные
welcome_msg    db 0x0D, 0x0A, "HFT OS 90 Kernel 0.2", 0x0D, 0x0A, 0
system_info    db "System initialized in real mode", 0x0D, 0x0A, 0
pmode_msg      db "Protected mode support planned for v0.3", 0x0D, 0x0A, 0
prompt         db 0x0D, 0x0A, "HFT> ", 0
help_msg       db 0x0D, 0x0A, "Commands: h-help, r-reboot, m-memory, c-cpu, ESC-halt", 0x0D, 0x0A, 0
reboot_msg     db 0x0D, 0x0A, "Rebooting system...", 0x0D, 0x0A, 0
halt_msg       db 0x0D, 0x0A, "System halted.", 0x0D, 0x0A, 0
unknown_cmd    db 0x0D, 0x0A, "Unknown command. Type 'h' for help.", 0x0D, 0x0A, 0

memory_info    db 0x0D, 0x0A, "Base memory: "
base_memory_kb dw 0
               db " KB", 0x0D, 0x0A, 0

cpu_info       db 0x0D, 0x0A, "CPU: 8086/88 compatible"
has_cpuid      db 0
               db 0x0D, 0x0A, 0

; Заголовок ядра (должен быть в начале файла)
header_start:
    db 'H', 'F', 'T', 'K'      ; Сигнатура
    dw (end_kernel - header_start + 511) / 512 ; Количество секторов
    times 512-($-header_start) db 0

end_kernel:
