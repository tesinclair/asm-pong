

global sqrt

; @param:
;       - rdi: number to square root (max 1 doubleword)
; @returns:
;       - rax: the numbers square root
; @function:
;       - Returns the positive square root of the number
;         rounded up
sqrt:
    push r9 ; for calc
    push rbx ; guess
    push rdx

    cmp rdi, 0
    je .sqrt_ret_self
    cmp rdi, 1
    je .sqrt_ret_self

    ; divide number by 6
    mov rax, rdi
    mov r9, 6
    xor rdx, rdx
    div r9
    mov rbx, rax

    mov r9, rbx
    imul r9, r9
    cmp r9, rdi
    jl .while_guess_l_n
    jg .while_guess_g_n
    je .sqrt_ret

.while_guess_g_n: ; while guess^2 > n
    dec rbx
    mov r9, rbx
    imul r9, r9
    cmp r9, rdi
    jg .while_guess_g_n

.while_guess_l_n: ; while guess^2 < n
    inc rbx
    mov r9, rbx
    imul r9, r9
    cmp r9, rdi
    jl .while_guess_l_n 

; Should always lead to guess being ceil sqrt(n)

.sqrt_ret:
    mov rax, rbx

    pop rdx
    pop rbx
    pop r9

    ret
    
.sqrt_ret_self:
    mov rax, rdi
    pop rdx
    pop rbx
    pop r9
    ret
