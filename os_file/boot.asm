org 0x7C00
bits 16

KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 8

start:
    mov [BOOT_DRIVE], dl

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov si, boot_msg
    call print_string

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    mov bx, KERNEL_OFFSET
    int 0x13

    jc disk_error

    jmp 0x0000:KERNEL_OFFSET

disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

BOOT_DRIVE db 0
boot_msg db 'Booting TinyOS...', 13, 10, 0
error_msg db 'Disk read error!', 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
