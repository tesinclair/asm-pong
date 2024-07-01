

global sqrt

; @param:
;       - rdi: number to square root (max 1 quadword)
; @returns:
;       - rax: the numbers square root
; @function:
;       - Returns the square root of the number
;         to the nearest whole number
sqrt:
    push r10
    push rbx

    cmp rdi, 0
    js .sqrt_ret_err
    je .sqrt_ret_self

    cmp rdi, 1
    je .sqrt_ret_self
    
    mov rbx, rdi
    shr rbx, 1

.sqrt_guess_loop:
    mov rsi, rbx
    imul rsi, rsi
    sub rsi, rdi
    cmp rsi, 0
    je .sqrt_ret_guess

    mov rax, rdi
    div rbx
    mov rax, r10
    add rbx, r10
    shr rbx, 1

    jmp .sqrt_guess_loop

.sqrt_ret_guess:
    mov rax, rbx
    pop rbx
    pop r10
    ret
    
.sqrt_ret_err:
    mov rax, -1
    pop rbx
    pop r10
    ret

.sqrt_ret_self:
    mov rax, rdi
    pop rbx
    pop r10
    ret
