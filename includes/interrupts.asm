;Divide By Zero Exception Handler
div_zero_ex:
push 0x000000FF
call clear_screen

push .error
push dword 0x00FFFFFF
push word 50
push word 50
call draw_string
call switch_buffer
jmp $
O32 iret
.error:
db 'Division by 0: the computer tried to divide by zero.',0

;Double Fault Handler
double_fault_ex:
push 0x000000FF
call clear_screen

push .error
push dword 0x00FFFFFF
push word 50
push word 50
call draw_string
call switch_buffer
jmp $
O32 iret
.error:
db 'Double fault: something bad happened and now you need to reset your computer.',0

;General Protection Fault Handler
gpf_ex:
push 0x000000FF
call clear_screen

push .error
push dword 0x00FFFFFF
push word 50
push word 50
call draw_string
call switch_buffer
jmp $
O32 iret
.error:
db 'General protection fault: something is broken or the computer wrote to a bad spot.',0

;PIT (timer) Handler
pit_handler:
push eax
push edx

mov eax,[MS_COUNT]
mov edx,[MS_COUNT+4]
add edx,0xFFF600E9;fixed point for 0.999847466689909837728024727159
adc eax,0;basically if carry, inc eax
mov [MS_COUNT],eax
mov [MS_COUNT+4],edx

mov al,0x20
out 0x20,al ;send EOI to PIC

pop edx
pop eax

O32 iret

;Keyboard Handler
keyboard_handler:
push ax
push cx
mov al,10000000b
or [KEYS_PRESSED],al

.wait: ;this is to wait for the byte to be ready to be read
in  al, 0x64
test al, 0x01
jz  .wait

in al,0x60
cmp al,0xe0 ;test for escape
jne .cont

mov byte [.escaped], 1 ;escaped = 1
jmp .end

.cont:
cmp al,0x81;test if esc pressed.
jne .cont2
call init_mem ;reset game
;reset scores
mov dword [PADDLE1_SCORE],0
mov dword [PADDLE2_SCORE],0
jmp .end
.cont2:
mov cl,[.escaped]
test cl,cl
jz .end ;if not escaped then we don't care (since its not up down left or right key)



;if we are here that means we got an escaped character
mov byte [.escaped], 0 ;escaped = 0

;time for a big switch
cmp al,0x48
je .make_up

cmp al,0xc8
je .break_up

cmp al,0x50
je .make_down

cmp al,0xd0
je .break_down

cmp al,0x4b
je .make_left

cmp al,0xcb
je .break_left

cmp al,0x4d
je .make_right

cmp al,0xcd
je .break_right

jmp .end

.make_up:
mov cl,[KEYS_PRESSED]
or cl,1
mov [KEYS_PRESSED],cl
jmp .end

.break_up:
mov cl,[KEYS_PRESSED]
xor cl,1
mov [KEYS_PRESSED],cl
jmp .end

.make_down:
mov cl,[KEYS_PRESSED]
or cl,2
mov [KEYS_PRESSED],cl
jmp .end

.break_down:
mov cl,[KEYS_PRESSED]
xor cl,2
mov [KEYS_PRESSED],cl
jmp .end

.make_left:
mov cl,[KEYS_PRESSED]
or cl,4
mov [KEYS_PRESSED],cl
jmp .end

.break_left:
mov cl,[KEYS_PRESSED]
xor cl,4
mov [KEYS_PRESSED],cl
jmp .end

.make_right:
mov cl,[KEYS_PRESSED]
or cl,8
mov [KEYS_PRESSED],cl
jmp .end

.break_right:
mov cl,[KEYS_PRESSED]
xor cl,8
mov [KEYS_PRESSED],cl
jmp .end

.end:
mov al,0x20
out 0x20,al ;send EOI to PIC

pop cx
pop ax
O32 iret
.escaped:
db 0

;##########################
;INTERRUPT DESCRIPTOR TABLE
idt_desc:
dw idt_end - idt - 1;Limit (size)
dd idt;offset

idt:
;Divide by 0 entry
dw div_zero_ex ;low word of offset
dw 08h ;selector, 8 = code
db 0 ;8 bits of 0 (for some reason)
db 10001110b;from left to right, present 1bit,privilege 2bits, storage segment (wtf) 1bit, type bit 4bits. (i hope this isn't back to front)
dw (div_zero_ex-kernel_start +0x10000) >> 16;high word of offset. 

dq 0
dq 0
dq 0
dq 0
dq 0 ;#5 0x5
dq 0
dq 0

;Double Fault entry
dw double_fault_ex ;low word of offset
dw 08h ;selector, 8 = code
db 0 ;8 bits of 0 (for some reason)
db 10001110b;from left to right, present 1bit,privilege 2bits, storage segment (wtf) 1bit, type bit 4bits. (i hope this isn't back to front)
dw (double_fault_ex-kernel_start +0x10000) >> 16;high word of offset. 

dq 0
dq 0 ;#10 0xA
dq 0
dq 0

;General Protection Fault entry
dw gpf_ex ;low word of offset
dw 08h ;selector, 8 = code
db 0 ;8 bits of 0 (for some reason)
db 10001110b;from left to right, present 1bit,privilege 2bits, storage segment (wtf) 1bit, type bit 4bits. (i hope this isn't back to front)
dw (gpf_ex-kernel_start +0x10000) >> 16;high word of offset. 

dq 0
dq 0 ;#15 0xF
dq 0
dq 0
dq 0
dq 0
dq 0 ;#20 0x14
dq 0
dq 0
dq 0
dq 0
dq 0 ;#25 0x19
dq 0
dq 0
dq 0
dq 0
dq 0 ;#30 0x1E
dq 0
;PIC INTERRUPTS START HERE:
;PIT (timer) handler
dw pit_handler ;low word of offset
dw 08h ;selector, 8 = code
db 0 ;8 bits of 0 (for some reason)
db 10001110b;from left to right, present 1bit,privilege 2bits, storage segment (wtf) 1bit, type bit 4bits. (i hope this isn't back to front)
dw (pit_handler-kernel_start +0x10000) >> 16;high word of offset. 

;Keyboard handler
dw keyboard_handler ;low word of offset
dw 08h ;selector, 8 = code
db 0 ;8 bits of 0 (for some reason)
db 10001110b;from left to right, present 1bit,privilege 2bits, storage segment (wtf) 1bit, type bit 4bits. (i hope this isn't back to front)
dw (keyboard_handler-kernel_start +0x10000) >> 16;high word of offset. 
idt_end:
