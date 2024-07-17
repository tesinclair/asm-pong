%define SCREEN_WIDTH 3200
%define SCREEN_HEIGHT 2160 - 165
%define RECT_HEIGHT 300
%define RECT_WIDTH 100
%define BALL_RADIUS 30

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
;       - rax: the wall the ball collides with
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
    jg .test_ball_rect_2_collision ; A is false

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
    jge .test_ball_rect_2_collision ; C is false

    jmp .get_angle_left ; collision with rect_1

.test_ball_rect_2_collision:
    ; A: (ball_y + radius) < (rect_2_y + rect_height)
    ; B: && (ball_y - radius) > rect_y
    ; C: && (ball_x - radius) <= SCREEN_WIDTH - rect_width

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
    sub r9, BALL_RADIUS
    cmp r9, SCREEN_WIDTH - RECT_WIDTH
    pop r9
    jge .test_ball_top_collision ; C is false

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
    ; ball_y + radius >= SCREEN_HEIGHT
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
    cmp r9, 0
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

; returns angle between 1 and 179
.get_angle_left:
    push rdi
    push rsi
    
    mov rdi, 1
    mov rsi, 179
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 181 and 359
.get_angle_right:
    push rdi
    push rsi
    
    mov rdi, 181
    mov rsi, 359
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 91 and 269
.get_angle_top:
    push rdi
    push rsi
    
    mov rdi, 91
    mov rsi, 269
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 271 and 360 because its easier than 270-360, 0-90
.get_angle_bottom:
    push rdi
    push rsi
    
    mov rdi, 271
    mov rsi, 360
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret



.ret_failure:
    mov rax, -1
    ret

