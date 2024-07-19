%define SCREEN_WIDTH 3200
%define SCREEN_HEIGHT 2160 - 165
%define RECT_HEIGHT 300
%define RECT_WIDTH 100
%define ERROR_MARGIN 5
%define BALL_RADIUS 30 + ERROR_MARGIN

%define LEFT_WALL 0
%define RIGHT_WALL 1

global collide

extern random
; @params:
;       - rdi: rect_1 y pos
;       - rsi: rect_2 y pos
;       - rdx: ball center x pos
;       - r10: ball center y pos
;       - r8: theta buffer, in degrees [r/w]
; @returns:
;       - rax: the wall the ball collides with or 2 if no wall
; @function:
;       - updates theta based on any collisions
collide:
.test_ball_rect_1_collision:
    ; A: (ball_y + radius) < (rect_1_y + rect_height)
    ; B: && (ball_y - radius) > rect_y
    ; C: && (ball_x - radius) <= rect_width

    ; A
    push r9
    push r11

    mov r9, r10
    add r9, BALL_RADIUS
    mov r11, rdi
    add r11, RECT_HEIGHT
    cmp r9, r11
    pop r11
    pop r9
    jge .test_ball_rect_2_collision ; A is false

    ; B
    push r9
    mov r9, r10
    sub r9, BALL_RADIUS
    cmp r9, rdi
    pop r9
    jle .test_ball_rect_2_collision ; B is false
    
    ; C
    push r9
    mov r9, rdx
    sub r9, BALL_RADIUS
    cmp r9, RECT_WIDTH
    pop r9
    jg .test_ball_rect_2_collision ; C is false

    jmp .get_angle_left ; collision with rect_1

.test_ball_rect_2_collision:
    ; A: (ball_y + radius) < (rect_2_y + rect_height)
    ; B: && (ball_y - radius) > rect_y
    ; C: && (ball_x + radius) >= SCREEN_WIDTH - rect_width

    ; A
    push r9
    push r11

    mov r9, r10
    add r9, BALL_RADIUS
    mov r11, rsi
    add r11, RECT_HEIGHT

    cmp r9, r11
    pop r11
    pop r9
    jg .test_ball_top_collision ; A is false

    ; B
    push r9
    mov r9, r10
    sub r9, BALL_RADIUS
    cmp r9, rsi
    pop r9
    jle .test_ball_top_collision ; B is false
    
    ; C
    push r9
    mov r9, rdx
    add r9, BALL_RADIUS
    push r8
    mov r8, SCREEN_WIDTH
    sub r8, RECT_WIDTH
    cmp r9, r8
    pop r8
    pop r9
    jl .test_ball_top_collision ; C is false

    jmp .get_angle_right ; collision with rect_1

.test_ball_top_collision:
    ; ball_y - radius <= 0
    push r9
    mov r9, r10
    sub r9, BALL_RADIUS
    cmp r9, 0
    pop r9
    jg .test_ball_bottom_collision

    jmp .get_angle_top

.test_ball_bottom_collision:
    ; ball_y + radius + erro_margin >= SCREEN_HEIGHT
    push r9
    mov r9, r10
    add r9, BALL_RADIUS
    cmp r9, SCREEN_HEIGHT
    pop r9
    jle .test_ball_right_wall_collision

    jmp .get_angle_bottom

.test_ball_right_wall_collision:
    ; ball_x - radius <= 0
    push r9
    mov r9, rdx
    sub r9, BALL_RADIUS
    cmp r9, 1
    pop r9
    jg .test_ball_left_wall_collision

    mov rax, 0
    ret

.test_ball_left_wall_collision:
    ; ball_y + radius >= SCREEN_HEIGHT
    push r9
    mov r9, rdx
    add r9, BALL_RADIUS
    cmp r9, SCREEN_WIDTH
    pop r9
    jle .no_collision_ret

    mov rax, 1
    ret

.no_collision_ret:
    mov rax, 2
    ret 

.collision_ret:
    mov [r8], rax
    mov rax, 2
    ret

; returns angle between 15 and 165
.get_angle_right:
    push rdi
    push rsi
    
    mov rdi, 15
    mov rsi, 165
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 195 and 345
.get_angle_left:
    push rdi
    push rsi
    
    mov rdi, 195
    mov rsi, 345
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 105 and 245
.get_angle_bottom:
    push rdi
    push rsi
    
    mov rdi, 105
    mov rsi, 245
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 285-345, 15-75
.get_angle_top:
    push rdi
    push rsi
    
    mov rdi, 0
    mov rsi, 1
    call random
    test rax, rax
    jz .bottom_left

.bottom_left:
    mov rdi, 15
    mov rsi, 75
    call random

    jmp .angle_bottom_fin

.bottom_right:
    mov rdi, 285
    mov rsi, 345
    call random

.angle_bottom_fin:
    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

.ret_failure:
    mov rax, -1
    ret

