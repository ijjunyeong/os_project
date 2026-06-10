# os_project

## os_project
부트로더 및 간단한 명령어 실행이 가능한 os

## 실행 환경
QEMU emulator version 10.2.50 (setup-20260307.exe)

NASM version 3.01

## 실행 방법
1. asm 파일 다운로드
2. cmd 또는 shell 실행 후 cd 명령어로 다운로드한 파일 폴더로 이동
4. "nasm -f bin 파일명.asm -o 파일명.bin"으로 boot, kernel 모두 .bin 파일 생성
5. "copy /b 부트파일명.bin+커널파일명.bin os-image.bin"로 병합한 os-image.bin 파일 생성
6. "qemu-system-i386 -drive format=raw,file=os-image.bin" qemu에서 os 파일 실행

#### OR

(qemu 설치는 공통)
1. os-image.bin 파일 다운로드
2. cmd에서 "qemu-system-i386 -drive format=raw,file=os-image.bin"으로 os 파일 실행

## 명령어

help : 명령어 목록

clear : 모든 텍스트 삭제

about : os에 대한 설명

color : 텍스트 색상 변경

reboot : 재부팅
