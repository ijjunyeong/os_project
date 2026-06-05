org 0x1000
bits 16

start:
    xor ax, ax
    mov ds, ax

    mov ss, ax
    mov sp, 0x9000

    ; 텍스트 모드 메모리 주소 설정
    ; 0xB8000에 입력시 바로 출력
    mov ax, 0xB800
    mov es, ax

    ; 화면 초기화
    call clear_screen

    ; 시작 메시지 출력
    mov si, title_msg
    call print_string

; 메인 반복문 명령어 입력 → 비교 → 실행

main_loop:
    mov si, prompt
    call print_string

    ; 입력 인풋 버퍼에 저장
    mov di, input_buffer
    call read_line

    ; help인가?
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp al, 1
    je do_help

    ; dlear인가?
    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    cmp al, 1
    je do_clear

    ; about인가?
    mov si, input_buffer
    mov di, cmd_about
    call strcmp
    cmp al, 1
    je do_about

    ; color인가?
    mov si, input_buffer
    mov di, cmd_color
    call strcmp
    cmp al, 1
    je do_color

    ; reboot인가?
    mov si, input_buffer
    mov di, cmd_reboot
    call strcmp
    cmp al, 1
    je do_reboot

    ; 명령어가 아닐 때
    mov si, unknown_msg
    call print_string
    jmp main_loop

; =========================
; 명령어 부분
; =========================

do_help:
    ; 명령어 목록 출력
    mov si, help_msg
    call print_string
    jmp main_loop

do_clear:
    ; 화면 지우기
    call clear_screen
    jmp main_loop

do_about:
    ; os 설명
    mov si, about_msg
    call print_string
    jmp main_loop

do_color:
    ; 글자 색상 변경, 1byte로 표현
    inc byte [text_color]

    mov si, color_msg
    call print_string
    jmp main_loop

do_reboot:
    ; 바이오스 재부팅
    int 0x19

; =========================
; print_string
; SI에 있는 문자열 출력
; 문자열은 0으로 끝남
; =========================

print_string:
    lodsb

    ; AL이 0이면 문자열 끝
    cmp al, 0
    je .done

    ; 문자 1개 출력
    call print_char

    ; 다음 문자 출력
    jmp print_string

.done:
    ret

; =========================
; print_char
; AL에 있는 문자 1개 출력
; =========================

print_char:
    ; 현재 레지스터 값들을 스택에 저장, 함수 외부에 영향을 주지 않도록 하기 위함
    pusha

    cmp al, 13
    je .newline
    cmp al, 10
    je .newline

    ; 커서 위치 저장
    mov di, [cursor_pos]

    ; 짝수 바이트 = 문자
    ; 홀수 바이트 = 색상
    mov [es:di], al

    ; 색상 적용
    mov ah, [text_color]
    mov [es:di+1], ah

    ; 문자는 2바이트이니 커서 2 증가
    add word [cursor_pos], 2
    jmp .done

.newline:
    ; 한 줄은 80글자 × 2바이트 = 160바이트
    ; 160으로 나누어 현재 줄 번호 구함
    mov ax, [cursor_pos]
    mov bx, 160
    xor dx, dx
    div bx

    ; 다음 줄로 이동
    inc ax

    ; 줄 번호 × 160에서 다음 줄 시작
    mul bx
    mov [cursor_pos], ax

.done:
    ; 스택에 저장해둔 레지스터 복구
    popa
    ret

; =========================
; read_line
; 키보드 입력을 input_buffer에 저장
; Enter 누르면 입력 종료, 백스페이스는 입력시 글자 삭제
; =========================

read_line:
    ; 입력한 글자 수
    xor cx, cx

.read_key:
    ; BIOS 키보드 인터럽트
    ; AL = ASCII 코드
    ; AH = 스캔 코드
    mov ah, 0
    int 0x16

    ; ASCII 13 = Enter
    cmp al, 13
    je .enter

    ; ASCII 8 = 백스페이스
    cmp al, 8
    je .backspace

    ; 입력 크기 제한
    ; input_buffer는 32바이트
    ; 입력은 30글자까지만 받음
    cmp cx, 30
    jae .read_key

    ; 입력 문자 버퍼에 저장
    mov [di], al
    inc di
    inc cx

    ; 입력 문자 화면 출력
    call print_char
    jmp .read_key

.backspace:
    ; 입력 없으면 패스
    cmp cx, 0
    je .read_key

    ; 버퍼 위치, 글자 수 하나 줄임
    dec di
    dec cx
    mov byte [di], 0

    ; 화면에서도 마지막 글자를 지우고 한칸 뒤로 이동
    sub word [cursor_pos], 2

    ; 공백으로 기존 글자 덮어쓰기
    mov al, ' '
    call print_char

    ; 다시 커서 한 칸 뒤로 이동
    sub word [cursor_pos], 2
    jmp .read_key

.enter:
    ; 문자열 끝 표시
    mov byte [di], 0

    ; 줄바꿈
    mov al, 13
    call print_char
    ret

; =========================
; clear_screen
; 화면 전체를 공백으로 채움
; 화면 크기: 80 × 25 = 2000 문자
; =========================

clear_screen:
    pusha

    ; 텍스트 메모리 세그먼트 설정
    mov ax, 0xB800
    mov es, ax

    ; 화면 시작 위치
    xor di, di

    ; 2000개 문자 지움
    mov cx, 2000

.clear_loop:
    ; 문자 부분에 공백 저장
    mov byte [es:di], ' '

    ; 색상 부분에 현재 색상 저장
    mov al, [text_color]
    mov byte [es:di+1], al

    ; 다음 문자 칸으로 이동
    add di, 2

    ; CX 1 감소시키고 0 아니면 반복
    loop .clear_loop

    ; 커서를 화면 맨 앞으로 이동
    mov word [cursor_pos], 0

    ; 레지스터 복구
    popa
    ret

; =========================
; strcmp
; 문자열 비교 함수
; =========================

strcmp:
.loop:
    ; 두 문자열의 현재 문자 읽기
    mov al, [si]
    mov bl, [di]

    ; 문자가 다르면 실패
    cmp al, bl
    jne .not_equal

    ; 둘 다 같을 때, 값이 0이면 두 문자열 같은
    cmp al, 0
    je .equal

    ; 다음 문자로 이동
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

; 현재 커서 위치
; 텍스트 모드는 문자 1개당 2바이트
cursor_pos dw 0

; 글자 색상, 검은배경 흰글자
text_color db 0x0F

; 입력 저장 공간
input_buffer times 32 db 0

; 명령어 문자열
cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_about db 'about', 0
cmd_color db 'color', 0
cmd_reboot db 'reboot', 0

; 출력 메시지
title_msg db 'TinyOS v0.1', 13, 'Type help to see commands.', 13, 13, 0
prompt db '> ', 0

help_msg db 'Commands: help, clear, about, color, reboot', 13, 0
about_msg db 'TinyOS is a simple 16-bit educational OS.', 13, 0
color_msg db 'Text color changed.', 13, 0
unknown_msg db 'Unknown command.', 13, 0

; 커널 크기를 4096바이트로 맞춤
; bootloader가 8섹터를 읽도록 설정했기 때문
; 1섹터 = 512바이트, 8섹터 = 4096바이트
times 4096-($-$$) db 0
