; TODO: 
;   - File i/o with /dev/fb0
;   - Basic Pong Shapes
;   - User Input
;   - Ball physics
;   - Game Loop
;   - Scores
;   - Quit on q

%define WIDTH 3200
%define HEIGHT 2000

global _start

section .text
_start:
    ; Open /dev/fb0
    mov rax, 2
    mov rdi, fb0_path
    mov rsi, 0x241
    mov rdx, 0o644
    syscall

    cmp rax, -1
    je exit_failure

    mov [fb0_fd], rax

    mov rsi, success_str
    mov rdx, success_str_len
    call print

    jmp exit_success

exit_failure:
    mov rax, 60
    mov rdi, 1
    syscall

exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

; @params: takes a buf and count in rsi, and rdx
print:
    push rax
    push rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    pop rax
    ret

section .data
    fb0_path db "/dev/fb0", 0
    success_str db "Successfully opened fb0", 10
    success_str_len equ $ - success_str 

section .bss
    fb0_fd resb 1
    




