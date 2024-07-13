%define PI 3.142

global sqrt
global cos
global sin

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

; @params:
;       - xmm0: decimal to round
; @function:
;       - rounds to 2 decimal places
; @returns:
;       - xmm0: rounded number
round_2_decimal_places:
    ; method:
    ;   - multiply by 100 (2 decimals)
    ;   - add 0.5 (rounds)
    ;   - convert to integer (truncate)
    ;   - convert back
    ;   - divide by 100

    push r9

    mulsd xmm0, [hundred] 
    mov rax, 5
    cvtsi2sd xmm1, rax
    divsd xmm1, [two] 
    addsd xmm0, xmm1

    cvtsd2si r9, xmm0
    cvtsi2sd xmm0, r9

    divsd xmm0, [hundred] 

    pop r9
    ret

; @params:
;       - rdi: angle theta in degrees [readonly]
; @function:
;       - performs a sine operation to 2 d.p.
; @returns:
;       - xmm0: result to 2 decimal places
cos:
    ; taking advantage of cos(x) = sin(pi/2 - x)

    push r9

    movsd xmm1, [pi] 
    divsd xmm1, [two] ; pi/2

    cvtsd2si r9, xmm1
    sub r9, rdi  ; pi/2 - x

    push rdi
    mov rdi, r9
    call sin ; sin(pi/2 - x)

    pop rdi
    pop r9

    ret ; result already in xmm0

; @params:
;       - rdi: angle theta in degrees [readonly]
; @function:
;       - performs a sine operation to 2 d.p.
; @returns:
;       - xmm0: result to 2 decimal places
sin:
    ; using approximation: 
    ;       y = (4*theta^2)/(PI^2) * (PI - theta)
    push r9

    mov r9, rdi
    imul r9, r9
    imul r9, 4 ; 4 * theta^2
    cvtsi2sd xmm0, r9

    movsd xmm1, [pi]
    ; push xmm1 to stack
    sub rsp, 16
    movdqu [rsp], xmm1
    mulsd xmm1, xmm1 ; PI^2
    divsd xmm0, xmm1 ; (4*theta^2)/(PI^2)
    ; pop xmm1
    movdqu xmm0, [rsp]
    add rsp, 16

    cvtsi2sd xmm2, rdi
    subsd xmm0, xmm2

    mulsd xmm0, xmm1 ; (4*theta^2)/(PI^2) * (PI - theta)
    call round_2_decimal_places

    pop r9

    ret


section .data
    pi dq 3.142
    hundred dq 100.0
    two dq 2.0
