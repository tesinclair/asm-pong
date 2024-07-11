global move_ball
global move_ai

; libmath
extern sin
extern cos

%define MOVE_SPEED 4
%define SCREEN_WIDTH 3200
%define SCREEN_HEIGHT 2160
%define USABLE_HEIGHT 2160 - 165

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
    push
    mov rdi, r9
    call cos
    pop rdi
    mov r9, rax
    test rax, rax
    js .move_ball_failure

    imul r9, MOVE_SPEED 

    add rbx, r9
    cmp rbx, USABLE_HEIGHT
    jg .calc_x
    cmp rbx, 0
    js .calc_x

    mov [rsi], rbx

    ; x
.calc_x:
    mov r9, rdx

    push rdi
    mov rdi, r9
    call sin
    pop rdi
    mov r9, rax
    test rax, rax
    js .move_ball_failure

    imul r9, MOVE_SPEED
    imul r9, -1

    add r10, r9
    cmp r10, WIDTH
    jg .move_ball_ret
    cmp r10, 0
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
    mov rbx, [rdi]
    cmp rbx, rsi
    jl .move_ai_up ; if y_pos < ball_y_pos
    jg .move_ai_down ; if y_pos < ball_y_pos
    
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
    cmp rbx, USABLE_HEIGHT
    jg .move_ai_return ; exit if at bottom

    mov [rdi], rbx
    jmp .move_ai_return
    
