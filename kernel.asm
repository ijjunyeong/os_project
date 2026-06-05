org 0x1000
bits 16

start:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x9000

    mov ax, 0xB800
    mov es, ax

    call clear_screen

    mov si, title_msg
    call print_string

main_loop:
    mov si, prompt
    call print_string

    mov di, input_buffer
    call read_line

    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp al, 1
    je do_help

    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    cmp al, 1
    je do_clear

    mov si, input_buffer
    mov di, cmd_about
    call strcmp
    cmp al, 1
    je do_about

    mov si, input_buffer
    mov di, cmd_color
    call strcmp
    cmp al, 1
    je do_color

    mov si, input_buffer
    mov di, cmd_reboot
    call strcmp
    cmp al, 1
    je do_reboot

    mov si, unknown_msg
    call print_string
    jmp main_loop

do_help:
    mov si, help_msg
    call print_string
    jmp main_loop

do_clear:
    call clear_screen
    jmp main_loop

do_about:
    mov si, about_msg
    call print_string
    jmp main_loop

do_color:
    inc byte [text_color]
    mov si, color_msg
    call print_string
    jmp main_loop

do_reboot:
    int 0x19

; =========================
; print string
; =========================

print_string:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp print_string
.done:
    ret

print_char:
    pusha

    cmp al, 13
    je .newline
    cmp al, 10
    je .newline

    mov di, [cursor_pos]
    mov [es:di], al
    mov ah, [text_color]
    mov [es:di+1], ah
    add word [cursor_pos], 2
    jmp .done

.newline:
    mov ax, [cursor_pos]
    mov bx, 160
    xor dx, dx
    div bx
    inc ax
    mul bx
    mov [cursor_pos], ax

.done:
    popa
    ret

; =========================
; keyboard
; =========================

read_line:
    xor cx, cx

.read_key:
    mov ah, 0
    int 0x16

    cmp al, 13
    je .enter

    cmp al, 8
    je .backspace

    cmp cx, 30
    jae .read_key

    mov [di], al
    inc di
    inc cx
    call print_char
    jmp .read_key

.backspace:
    cmp cx, 0
    je .read_key

    dec di
    dec cx
    mov byte [di], 0

    sub word [cursor_pos], 2
    mov al, ' '
    call print_char
    sub word [cursor_pos], 2
    jmp .read_key

.enter:
    mov byte [di], 0
    mov al, 13
    call print_char
    ret

; =========================
; clear
; =========================

clear_screen:
    pusha
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000

.clear_loop:
    mov byte [es:di], ' '
    mov al, [text_color]
    mov byte [es:di+1], al
    add di, 2
    loop .clear_loop

    mov word [cursor_pos], 0
    popa
    ret

; =========================
; compare string
; SI = 입력 문자열
; DI = 명령어 문자열
; 결과 AL = 1이면 같음
; =========================

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]

    cmp al, bl
    jne .not_equal

    cmp al, 0
    je .equal

    inc si
    inc di
    jmp .loop

.equal:
    mov al, 1
    ret

.not_equal:
    mov al, 0
    ret

; =========================
; data
; =========================

cursor_pos dw 0
text_color db 0x0F

input_buffer times 32 db 0

cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_about db 'about', 0
cmd_color db 'color', 0
cmd_reboot db 'reboot', 0

title_msg db 'TinyOS v0.1', 13, 'Type help to see commands.', 13, 13, 0
prompt db '> ', 0

help_msg db 'Commands: help, clear, about, color, reboot', 13, 0
about_msg db 'TinyOS is a simple 16-bit educational OS.', 13, 0
color_msg db 'Text color changed.', 13, 0
unknown_msg db 'Unknown command.', 13, 0

times 4096-($-$$) db 0