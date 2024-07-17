%define PI 3.142

global sqrt
global cos
global sin
global random

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

    ; num // 6
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
    ; using taylor series: 
    ;       y = x + x^3/3! + x^5/5! + x^7/7! ;; x = theta
    ; accurate in the interval [-pi/2, pi/2]
    push r9

    call map_theta
    call cvt_theta_to_rads ; returns to xmm0

    mov r9, rdi ; theta
    imul r9, rdi
    imul r9, rdi ; x^3
    cvtsi2sd xmm0, r9
    movsd xmm1, [three_factorial]
    divsd xmm0, xmm1 ; x^3/3!

    imul r9, rdi
    imul r9, rdi ; x^5
    cvtsi2sd xmm1, r9
    movsd xmm2, [five_factorial]
    divsd xmm1, xmm2 ; x^5/5!

    addsd xmm0, xmm1 ; x^3/3! + x^5/5!

    imul r9, rdi
    imul r9, rdi ; x^7
    cvtsi2sd xmm1, r9
    movsd xmm2, [seven_factorial]
    divsd xmm1, xmm2 ; x^7/7!

    addsd xmm0, xmm1 ; x^3/3! + x^5/5! + x^7/7!

    cvtsi2sd xmm1, rdi
    addsd xmm0, xmm1 ; x + x^3/3! + x^5/5! + x^7/7!

    call round_2_decimal_places

    pop r9

    ret

; @params:
;       - rdi: theta
; @function:
;       - takes a theta - in degrees
;         and converts it to radians
cvt_theta_to_rads:
    ; rads = x * pi/180
    cvtsi2sd xmm0, rdi
    
    sub rsp, 16
    movdqu [rsp], xmm1 ; push xmm1

    movsd xmm1, [pi]
    divsd xmm1, [hundred_eighty]

    mulsd xmm0, xmm1 ; x * pi/180

    movdqu xmm1, [rsp] ; restore xmm1
    add rsp, 16

    ret ; return xmm0

; @params:
;       - rdi: theta
; @function:
;       - takes a theta - in degrees
;         and maps it to the inteval [-90, 90]
; @returns:
;       - rax: mapped theta
map_theta:
    ; alg:
    ;   (theta + 180) % 360 - 180 ;; get within -180, 180
    ;   if theta > 90:
    ;       theta = 180 - theta
    ;   if theta < -90:
    ;       theta = -180 - angle

    push rdi

    add rdi, 180 
    mov rdx, 360
    call mod

    sub rax, 180

    cmp rax, 90
    jg .theta_greater_90
    cmp rax, -90
    jl .theta_less_m_90

    pop rdi

    ret

.theta_greater_90:
    mov rdi, 180
    sub rdi, rax
    mov rax, rdi

    pop rdi
    ret

.theta_less_m_90:
    mov rdi, -180
    sub rdi, rax
    mov rax, rdi

    pop rdi
    ret

; @params:
;       - rdi: x
;       - rdx: y
; @function:
;       - take an x and a y and calculates x % y
; @returns:
;       - rax: x % y
mod:
    ; equation:
    ;   x % y = x - y(x // y)

    push rsi

    mov rax, rdi ; x
    mov rsi, rdx ; y
    xor rdx, rdx
    div rsi ; x // y
    mov rdx, rsi

    imul rax, rdx ; y(x // y)
    sub rdi, rax
    mov rax, rdi

    pop rsi

    ret

; @params:
;       - rdi: lower bound (inclusive)
;       - rsi: upper bound (inclusive)
; @function:
;       - returns a number between rdi
;         and rsi in rax
; @returns:
;       - rax: random number
random:
    push rbx
    push rdi
    ; sysbrk
    mov rax, 12
    xor rdi, rdi
    syscall

    mov rbx, rax

    add rax, 17
    mov rdi, rax
    mov rax, 12
    syscall

    pop rdi

    cmp rax, rbx
    je .random_no_memory_failure

    push rdi
    push rsi
    ; sys_getrandom
    mov rax, 318
    mov rdi, rbx
    mov rsi, 16
    xor rdx, rdx
    syscall
    ; now random buf has 16 random bytes

    pop rsi
    pop rdi

    test rax, rax
    js .random_ret_failure

    mov rax, qword [rbx]

    push rsi
    push rdi
    push rdx

    sub rsi, rdi
    mov rdi, rax
    mov rdx, rsi
    call mod ; random % (upper - lower) 

    pop rdx
    pop rdi
    pop rsi

    test rax, rax
    js .random_ret_failure
    
    push r9
    mov r9, rax
    mov rax, rdi
    add rax, r9
    pop r9

    pop rbx

    ret

.random_ret_failure:
    push rdi 
    mov rdi, rbx
    mov rax, 12
    syscall ; deallocate

    pop rdi
    pop rbx
    mov rax, -1
    ret

.random_no_memory_failure:
    pop rbx
    mov rax, -1
    ret

section .data
    pi dq 3.142
    hundred dq 100.0
    two dq 2.0
    hundred_eighty dq 180.0
    three_factorial dq 6.0
    five_factorial dq 120.0
    seven_factorial dq 5040.0
