org 0x7C00
bits 16

KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 8

start:
    ; 부팅 드라이브 번호 저장
    mov [BOOT_DRIVE], dl

    ; 세그먼트와 스택 초기화
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 부팅 메시지 출력
    mov si, boot_msg
    call print_string

    ; 디스크의 2번 섹터 커널 읽기
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    mov bx, KERNEL_OFFSET
    int 0x13

    ; 실패시 에러 출력
    jc disk_error

    ; 커널로 이동
    jmp 0x0000:KERNEL_OFFSET

; 에러 메세지 출력
disk_error: 
    mov si, error_msg
    call print_string
    jmp $

; 문자열 출력 함수
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

; 남은 공간을 모두 0으로 채움
times 510-($-$$) db 0
; 부트 마지막은 512byte
dw 0xAA55
