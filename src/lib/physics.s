global move_ball
global move_ai

; libmath
extern sin
extern cos
extern mod

%define MOVE_SPEED 1
%define SCREEN_WIDTH 3200
%define SCREEN_HEIGHT 2160
%define USABLE_HEIGHT 2160 - 165
%define BALL_RADIUS 30
%define RECT_HEIGHT 300

; @params:
;       - rdi: x_pos buffer [read/write]
;       - rsi: y_pos buffer [read/write]
;       - rdx: theta (current angle) [read]
; @function:
;       - updates the x and y pos based on the 
;         ball movement speed and angle
move_ball:
    ; y = mvt_speed * cos(theta)
    ; x = - mvt_speed * sin(theta)

    push rbx
    push r10
    push r9

    mov rbx, [rsi] ; y
    mov r10, [rdi] ; x
    mov r9, rdx ; theta

    ; y
    push rdi
    mov rdi, r9
    call cos ; cos theta
    pop rdi
    test rax, rax ; errors in rax
    js .move_ball_failure

    ; returns in xmm0
    mulsd xmm0, [move_speed_f]
    cvtsd2si r9, xmm0 ; floor
    cmp r9, MOVE_SPEED
    jle .no_set_max_y ; not above move speed
    mov r9, MOVE_SPEED

.no_set_max_y:
    add rbx, r9
    push rbx
    add rbx, BALL_RADIUS
    cmp rbx, USABLE_HEIGHT
    pop rbx
    jge .calc_x
    push rbx
    sub rbx, BALL_RADIUS
    cmp rbx, 10 ; seems to be an issue with the highest area...
    pop rbx
    jle .calc_x

    mov [rsi], rbx

    ; x
.calc_x:
    mov r9, rdx

    push rdi
    mov rdi, r9
    call sin
    pop rdi
    test rax, rax
    js .move_ball_failure

    mulsd xmm0, [move_speed_f]
    cvtsd2si r9, xmm0 ; floor
    imul r9, -1
    add r10, r9

    cmp r9, MOVE_SPEED
    jle .no_set_max_x
    mov r9, MOVE_SPEED

.no_set_max_x:
    push r10
    add r10, BALL_RADIUS
    cmp r10, SCREEN_WIDTH
    pop r10
    jg .move_ball_ret
    push r10
    sub r10, BALL_RADIUS
    cmp r10, 0
    pop r10
    js .move_ball_ret

    mov [rdi], r10
    
.move_ball_ret:
    pop r9
    pop r10
    pop rbx
    xor rax, rax
    ret

.move_ball_failure:
    pop r9
    pop r10
    pop rbx
    mov rax, -1
    ret

; @params:
;       - rdi: y_pos buffer [read/write]
;       - rsi: ball_y_pos [read]
; @function:
;       - moves ai by its movement speed
;         in the direction of ball
move_ai:
    push rbx
    push r8
    mov r8, RECT_HEIGHT / 2
    add r8, [rdi]
    mov rbx, [rdi]
    cmp r8, rsi ; cmp y_pos, ball_y_pos
    pop r8
    jl .move_ai_down ; if y_pos < ball_y_pos
    jg .move_ai_up ; if y_pos > ball_y_pos
    
.move_ai_return:
    pop rbx
    xor rax, rax
    ret

.move_ai_up:
    sub rbx, MOVE_SPEED
    test rbx, rbx
    js .move_ai_return ; exit if at roof

    mov [rdi], rbx
    jmp .move_ai_return

.move_ai_down:
    add rbx, MOVE_SPEED
    push rbx
    add rbx, RECT_HEIGHT
    cmp rbx, USABLE_HEIGHT
    pop rbx
    jge .move_ai_return ; exit if at bottom

    mov [rdi], rbx
    jmp .move_ai_return
    
section .data
    move_speed_f dq 1.0
