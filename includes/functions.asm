[BITS 32]

;################################################################################
;################################################################################
;################################################################################
;Update
;################################################################################
;################################################################################
;################################################################################
update:
mov dl,[KEYS_PRESSED]
test dl, 10000000b;test if keys have indeed been pressed.
jz .end ;if not the game is paused and we shouldn't update.

;update paddle 1
mov eax,[PADDLE1_POS]

test dl,1
jz .skip
sub eax,8
.skip:

test dl,2
jz .skip2
add eax,8
.skip2:

cmp eax,0
jge .skip3
mov eax,0
.skip3:

cmp eax,video_height - paddle_height
jng .skip4
mov eax,video_height - paddle_height
.skip4:
mov [PADDLE1_POS],eax

;update ball

fld dword [BALLX]
fwait
fadd dword [BALLSPEEDX]
fwait
fstp dword [BALLX]

fwait
fld dword [BALLY]
fwait
fadd dword [BALLSPEEDY]
fwait
fstp dword [BALLY]
fwait

;check top and bottom of screen.
fldz
fwait
fld dword [BALLY]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf
jb .ybelow0
jmp .ynotbelow0
.ybelow0:
;set bally to 0
fldz
fwait
fstp dword [BALLY]
fwait

;reverse ballspeedy
mov dword[.tempfloat],-1
fld dword [BALLSPEEDY]
fwait
fimul dword [.tempfloat]
fwait
fstp dword [BALLSPEEDY]
fwait
jmp .finishedball;no point checking the bottom if it hit the top

;check bottom
.ynotbelow0:
mov dword [.tempfloat],ball_screen_bottom
fld dword[.tempfloat]
fwait
fld dword [BALLY]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf
ja .yabovemax
jmp .finishedball
.yabovemax:
;set bally to max
mov dword [BALLY],ball_screen_bottom
;reverse ballspeedy
mov eax,-1
mov [.tempfloat],eax
fld dword [BALLSPEEDY]
fwait
fimul dword [.tempfloat]
fwait
fstp dword [BALLSPEEDY]
fwait
.finishedball:

;update paddle 2
;first check if ball is heading towards paddle 2
fwait
fldz
fwait
fld dword [BALLSPEEDX]
fwait
fcompp
fwait
fstsw ax
fwait
sahf
ja .xpos
jmp .finishedpaddle2
.xpos: ;x positive (ball heading towards paddle 2)
fld dword [BALLY]
fwait
fistp dword [.tempfloat]
fwait
mov eax,[.tempfloat];eax = ballY
add eax,ball_radius;eax = middle of ball
mov ecx,[PADDLE2_POS];ecx = paddle2pos
mov edx,ecx;edx = paddle2pos
add edx,paddle_height / 2 ;edx = middle of paddle

sub eax,edx
cmp eax,8
jng .checkbottom
;if we are here eax > 8 and should be set to 8.
mov eax,8
jmp .storepaddle2

.checkbottom:
cmp eax,-8
jnl .storepaddle2
mov eax,-8
.storepaddle2:
add ecx, eax
cmp ecx,0
jge .skip5
mov ecx,0
.skip5:

cmp ecx,video_height - paddle_height
jng .skip6
mov ecx,video_height - paddle_height
.skip6:

mov [PADDLE2_POS],ecx
.finishedpaddle2:



;check left paddle and screen
;check it hasn't passed the left edge of the screen
fldz;load 0
fwait
fld dword [BALLX]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf ;set the comparison stuff into the flags
jb .xbelow0
jmp .xnotpassed0
.xbelow0: ;if ballx is below 0, left lost.
;first negate speed.
call init_mem ;reset game
inc dword [PADDLE2_SCORE]
jmp .end ;left lost that round, no point running any more game logic
.xnotpassed0:

;check if it has passed the left paddle.
mov dword [.tempfloat],ball_paddle_left

fld dword [.tempfloat]
fwait
fld dword [BALLX]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf
jb .xpassedlp
jmp .finishedleft
.xpassedlp: ;X below left paddle
;if we are here then it has passed the paddle but not the edge of the screen
fld dword [BALLY]
fwait
fistp dword [.tempfloat] ;.tempfloat now contains the ball y
fwait
mov eax, [.tempfloat];eax contains ball y.

mov ebx,eax;save bally for later

mov ecx, [PADDLE1_POS]
sub ecx, ball_radius*2
cmp eax,ecx
jg .ybelowlptop
jmp .finishedpaddles ;we know it has passed the left paddle so no point checking right
.ybelowlptop: ;Y below left paddle top
add ecx,ball_radius*2
add ecx,paddle_height;ecx = paddle bottom
cmp eax,ecx
jl .yabovelpbottom
jmp .finishedpaddles
.yabovelpbottom: ;Y above left paddle bottom


;if we are here the ball has hit the left paddle.
;set the ball x position to against the paddle

mov dword[BALLX],ball_paddle_left
;negate the speed
mov dword[.tempfloat],-1
fld dword [BALLSPEEDX]
fwait
fimul dword [.tempfloat]
fwait
fstp dword [BALLSPEEDX]
fwait

mov eax,[PADDLE1_POS]
add eax,paddle_height / 2
add ebx,ball_radius;so ebx = middle of ball
sub ebx,eax;ebx = difference between ball and paddle.
mov [.tempfloat],ebx
fild dword [.tempfloat]
fwait
mov dword [.tempfloat],ball_y_bounce_divisor
fdiv dword [.tempfloat]
fwait
fadd dword [BALLSPEEDY]
fwait
fstp dword [BALLSPEEDY]
fwait
;now that we know its hit the left paddle, no point doing stuff for the right paddle
jmp .finishedpaddles
.finishedleft:


;finished left paddle, check right


;check right paddle
;check it hasn't passed the right edge of the screen
mov dword [.tempfloat],ball_screen_right
fld dword [.tempfloat];load left of screen
fwait
fld dword [BALLX]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf ;set the comparison stuff into the flags
ja .xabovemax
jmp .xnotabovemax
.xabovemax: ;if ballx is below 0, left lost.
;first negate speed.
call init_mem ;reset game
inc dword [PADDLE1_SCORE]
jmp .end ;right lost that round, no point running any more game logic
.xnotabovemax:

;check if it has passed the right paddle.

mov dword [.tempfloat],ball_paddle_right

fld dword [.tempfloat]
fwait
fld dword [BALLX]
fwait
fcompp;compare and pop both of them off.
fwait
fstsw ax
fwait
sahf
ja .xpassedrp
jmp .finishedpaddles
.xpassedrp: ;X below right paddle
;if we are here then it has passed the paddle but not the edge of the screen

fld dword [BALLY]
fwait
fistp dword [.tempfloat] ;.tempfloat now contains the ball y
fwait
mov eax, [.tempfloat];eax contains ball y.

mov ebx,eax;save bally for later

mov ecx, [PADDLE2_POS]
sub ecx, ball_radius*2
cmp eax,ecx
jg .ybelowrptop
jmp .finishedpaddles ;finished if its above the paddle 
.ybelowrptop: ;Y below right paddle top
add ecx,ball_radius*2
add ecx,paddle_height;ecx = paddle bottom
cmp eax,ecx
jl .yaboverpbottom
jmp .finishedpaddles
.yaboverpbottom: ;Y above right paddle bottom



;if we are here the ball has hit the right paddle.
;set the ball x position to against the paddle

mov dword [BALLX],ball_paddle_right
;negate the speed
mov dword [.tempfloat],-1
fld dword [BALLSPEEDX]
fwait
fimul dword [.tempfloat]
fwait
fstp dword [BALLSPEEDX]
fwait

mov eax,[PADDLE2_POS]
add eax,paddle_height / 2
add ebx,ball_radius;so ebx = middle of ball
sub ebx,eax;ebx = difference

mov [.tempfloat],ebx

fild dword [.tempfloat]
fwait

mov dword [.tempfloat],ball_y_bounce_divisor
fdiv dword [.tempfloat]
fwait
fadd dword [BALLSPEEDY]
fwait
fstp dword [BALLSPEEDY]
fwait
;now that we know its hit the left paddle, no point doing stuff for the right paddle
jmp .finishedpaddles

.finishedpaddles:
.end:
ret
.tempfloat: ;same as the one in draw: this is used for temporarily storing floats.
dd 0
;################################################################################
;################################################################################
;################################################################################
;Convert Dword To Text
;################################################################################
;################################################################################
;################################################################################
;no registers saved.
;I copy pasted this from some old stuff i did in masm, so it may not 100% work, but seems to be fine.
;push number
;push text pointer
;call dwtoa
dwtoa:
push ebp
mov ebp,esp

mov edi,[ebp + 8]
mov esi,edi
mov ecx,10
mov eax,[ebp + 12]
;end setup---

test eax,eax
jnz .cont
;Below this is code for if the value is 0
mov byte [edi], 0x30
inc edi
mov byte [edi],0;terminator
jmp exit
	
.cont:
;Below this is code for writing digits in reverse order
push ebx ;apparently REALLY important make SURE this is the same at the end of the routine.
xor ebx,ebx ;this will be a counter for putting ',' characters in

.divloop:
xor edx,edx 
div ecx
add dl,0x30
mov byte [edi],dl
inc edi
;comma checking
inc ebx
cmp ebx,3
jnae .nocomma
test eax,eax
jz .writeterminator
mov byte [edi],','
inc edi
xor ebx,ebx
.nocomma:
test eax,eax
jnz .divloop
.writeterminator:
mov byte [edi],0;terminator
	
pop ebx 
;Below this is code for reversing numbers
reverse:
dec edi
mov al,[esi]
mov ah,[edi]
mov [esi],ah
mov [edi],al
inc esi
cmp edi,esi
ja reverse

exit:
pop edi
pop esi

leave
retn 8
;################################################################################
;################################################################################
;################################################################################
;Initialise
;################################################################################
;################################################################################
;################################################################################
;no registers saved and no params

;upon kernel entry, ecx = LFB address and edx = font pointer with interrupts disabled

initialise:
mov dword [LFB],ecx ;mov dword to LFB (front buffer)
mov dword [DRAWFB],0x00100000 ;mov drawing buffer ptr (back buffer)
mov byte [SCREENMODE],bl
mov dword [FONT_PTR],edx

call init_mem

;init FPU
mov eax,cr4
or eax,0x200;set 9th bit (to tell CPU we're using FPU stuff)
mov cr4,eax
finit;set all the fpu registers to default.

call init_interrupts

ret

;################################################################################
;################################################################################
;################################################################################
;Initialise Memory
;################################################################################
;################################################################################
;################################################################################
;no registers saved and no params
init_mem:
mov ax,(video_height/2) - (paddle_height/2)
mov [PADDLE1_POS],ax
mov [PADDLE2_POS],ax

mov dword [BALLX],ball_start_x
mov dword [BALLY],ball_start_y

mov dword [BALLSPEEDX],__float32__(-10.0)
mov dword [BALLSPEEDY],__float32__(0.0)

mov byte [KEYS_PRESSED],0;pauses the game

ret
;################################################################################
;################################################################################
;################################################################################
;Initialise Interrupts
;################################################################################
;################################################################################
;################################################################################
;no registers saved and no params
init_interrupts:

;PIC setup
;initialise word
mov al,0x11
out 0x20,al
call io_wait

out 0xA0,al
call io_wait

;offset word
mov al,0x20
out 0x21,al
call io_wait

mov al,0x28
out 0xA1,al
call io_wait

;some wierd config stuff
mov al,0x4
out 0x21,al
call io_wait

mov al,0x2
out 0xA1,al
call io_wait

;some more config stuff
mov al,0x1
out 0x21,al
call io_wait

out 0xA1,al
call io_wait

mov al,0xFF
out 0x0021,al;disable the PIC.
out 0x00A1,al;disable the other PIC.
;PIC should be set up now

;interrupts setup
lidt [idt_desc]
;interrupts should be setup now

;Unmasking for everything (but the PIT) goes here

;keyboard
in al,0x21
xor al,2;clear keyboard mask
out 0x21,al

;unmasking complete

;set up the PIT (timer. Done last because the time starts as soon as its set up)
mov al,00110100b;for the meaning of this, consult the OSdev wiki
out 0x43,al
mov ax,1193;divisor
out 0x40,al;low divisor byte
mov al,ah
out 0x40,al;high divisor byte

;unmask it on the PIC
in al,0x21
xor al,1;clear PIT mask
out 0x21,al
;Should be unmasked now.

sti ;interrupts on
ret

;################################################################################
;################################################################################
;################################################################################
;IO wait.
;################################################################################
;################################################################################
;################################################################################
;no registers changed and no params
;this is used for forcing the CPU to wait for old and slow devices to respond.
;mainly for compatability with old circuits as modern stuff should be fast enough to not need this.
io_wait:
push ax
in al,0x80
pop ax
ret 
