[BITS 32]

;################################################################################
;################################################################################
;################################################################################
;Draw 
;################################################################################
;################################################################################
;################################################################################
draw:
push dword 0x00000000;black
call clear_screen

mov al,[KEYS_PRESSED]
test al,10000000b
jnz .skip_title
push title_text
push dword 0x00FFFFFF
push word 300
push word 0
call draw_string
.skip_title:

;draw paddle 1
mov ax,paddle_height
add ax,[PADDLE1_POS]
push dword 0x00FF0000;push red colour code
push word 0;push word start x
push word [PADDLE1_POS];push word start y
push word paddle_width;push word end x
push word ax;push word end y
call draw_rect

;draw paddle 2
mov ax,paddle_height
add ax,[PADDLE2_POS]
push dword 0x000000FF;push blue colour code
push word video_width - paddle_width;push word start x
push word [PADDLE2_POS];push word start y
push word video_width;push word end x
push word ax;push word end y
call draw_rect

fwait
fld dword[BALLX]
fwait
fistp dword [.tempfloat]
fwait
mov ax,[.tempfloat]
fwait
fld dword[BALLY]
fwait
fistp dword [.tempfloat]
fwait
mov cx,[.tempfloat]
;draw ball (drawn from top left)
push dword 0x00FFFFFF;white
push word ax
push word cx
add ax,ball_radius * 2
push word ax
add cx,ball_radius * 2
push word cx
call draw_rect


;draw score1
push dword [PADDLE1_SCORE]
push score_num_text
call dwtoa

push score_text
push dword 0x00FFFFFF
push word 0
push word 0
call draw_string

;draw score2

push dword [PADDLE2_SCORE]
push score_num_text
call dwtoa

push score_text
push dword 0x00FFFFFF
push word video_width - 160
push word 0
call draw_string

;draw revision number
push text_rev
push dword 0x00404040
push word video_width - 160
push word video_height - 16
call draw_string

mov al,[SCREENMODE]
test al,al
jnz .draw24

call switch_buffer
ret

.draw24:
push text24bit
push dword 0x00404040
push word 0
push word video_height - 16
call draw_string
call switch_buffer
ret
.tempfloat: ;this is where to put floating point numbers that need to be loaded into registers since FPU cannot store directly into registers
dd 0
;################################################################################
;################################################################################
;################################################################################
;Draw Rectangle
;################################################################################
;################################################################################
;################################################################################
;Example:
;push dword colour code, formated 0x00:red:green:blue
;push word start x
;push word start y
;push word end x
;push word end y

;registers used
;eax,ebx,ecx,edx,edi,esi
;registers saved
;edi,esi
draw_rect:
push ebp
mov ebp,esp

push esi
push edi

xor eax,eax
mov ax,[ebp+12]		;mov ax, startY
mov ecx,video_width
mul ecx				;y*video_width = line

shl eax,2 ;y+x * 4 (for 32bpp)

mov edi,eax

add edi,dword [DRAWFB]
;edi = start line

xor eax,eax
mov ax,[ebp + 14]	;mov ax, startX
shl eax,2 ;mul by 4

mov esi,eax
push esi
;esi = x offset

;now we gotta calc x offset end and y end.
xor eax,eax
mov ax,[ebp + 10] ;mov ax, end x
shl eax,2 ;mul by 4

mov ecx,eax
;ecx X offset end

xor eax,eax
mov ax,[ebp+8]		;mov ax, end Y
mov edx,video_width
mul edx				;y*video_width = line

shl eax,2 ;y+x * 4

add eax,[DRAWFB]

pop ebx ;ebx = x offset (used to restore back to the old x offset when drawing the next line)

mov edx,[ebp + 16] ;edx = colour
.xloop:
mov dword [edi + esi],edx ;write blue and green.
add esi,4
cmp esi,ecx
jb .xloop

mov esi,ebx
add edi,video_width*4;it takes more than 3 opcodes to multiply edi by 3, so might as well do this.
cmp edi,eax
jb .xloop

pop edi
pop esi

leave
retn 12

;################################################################################
;################################################################################
;################################################################################
;Clear the screen to a colour
;################################################################################
;################################################################################
;################################################################################
;push dword colour code, formated 0x00:red:green:blue ebp+8
clear_screen:
push ebp
mov ebp,esp

mov edi,[DRAWFB]
mov ecx,edi
add ecx,video_length;ecx = buffer end position, edi = buffer start

mov eax,[ebp+8] ;eax = colour

.loop:
mov dword [edi],eax
add edi, 4
cmp edi,ecx
jb .loop;if edi < buffer end then we still need to copy

leave
retn 4
;################################################################################
;################################################################################
;################################################################################
;Switch Buffer (Copy back buffer to front)
;################################################################################
;################################################################################
;################################################################################
;no params
switch_buffer:
mov al,[SCREENMODE]
test al,al
jnz switch_buffer_24

push esi
push edi

mov esi, [DRAWFB]
mov edi, [LFB]

mov ecx,video_dword_length

cld ;copy forwards
rep movsd 

pop edi
pop esi
ret
;################################################################################
;################################################################################
;################################################################################
;Switch Buffer 32-24 (Copy back buffer to front where back is 32 bpp and front is 24bpp)
;################################################################################
;################################################################################
;################################################################################
;no params
switch_buffer_24:
push esi
push edi

mov esi, [DRAWFB]
mov edi, [LFB]

mov ecx,video_dword_length/4
;The trick to making this not massively slow is to only send aligned dwords to the gfx card
;The lowest common multiple of 3 and 4 is 12, which equates to 4 24bpp pixels per loop sent as 3 dwords
.loop:

mov eax,[esi]
ror eax,24;rotate eax to access the topmost byte
mov al,[esi+4]
ror eax,8 ;fix eax up
;first dword assembled in eax
mov [edi],eax;write it to GFX card

mov eax,[esi+5]
mov dx,ax
shr eax,24;shift to access the topmost byte of eax
ror edx,16;rotate to access the 3rd byte of edx(with dl) and topmost (with dh)
mov dl,al
mov dh,[esi+9]
ror edx,16;fix up edx
;second dword assembled in edx
mov [edi+4],edx;write it to GFX card

mov eax,[esi+10]
mov dl,al
shr eax,16
mov dh,al
ror edx,16
mov dl,ah
mov dh,[esi+14]
ror edx,16
;third dword assembled in edx
mov [edi + 8],edx;write it to memory

add edi,12
add esi,16

dec ecx
cmp ecx,0
ja .loop

pop edi
pop esi
ret
;################################################################################
;################################################################################
;################################################################################
;Draw Char
;################################################################################
;################################################################################
;################################################################################
;Example:
;push dword colour code, formated 0x00:red:green:blue ebp+14
;push word x	ebp+12
;push word y	ebp+10
;push word char ebp+8

;registers used
;eax,ecx,edx,edi,esi
;registers saved
;edi,esi
draw_char:
push ebp
mov ebp,esp

push esi
push edi

xor esi,esi;clearing registers

xor eax,eax
mov ax,[ebp+10];eax = y
mov ecx,video_width
mul ecx ;eax = y line

xor ecx,ecx
mov cx,[ebp+12];ecx = x column
add eax,ecx;eax = y+x

shl eax,2;eax = 4(y+x) = starting pixel
mov edi,eax
add edi,[DRAWFB] ;edi = drawbuffer

xor edx,edx
mov dx, [ebp+8]
shl edx,4 ;multiply by 16
add edx, [FONT_PTR] ;edx now = the letter position.

xor eax,eax ;used as a counter
mov ebx,[ebp + 14] ;ebx = colour

.lineloop:
mov cl,[edx+eax];cl = font line
mov ch,10000000b ;ch = mask.

.loop:
test cl,ch
jz .cont
;drawing the dots.
mov dword [edi+esi],ebx ;write colour
.cont:
add esi,4
shr ch,1 ;move the mask over one bit to test the next bit.
test ch,ch ;if its 0 we've drawn all the dots.
jnz .loop

inc eax
cmp eax,16
jnl .end

add edi,video_width*4;it takes more than 3 opcodes to multiply edi by 3, so might as well do this.
xor esi,esi
jmp .lineloop
.end:
pop edi
pop esi

leave
retn 10

;################################################################################
;################################################################################
;################################################################################
;Draw String (null terminated)
;################################################################################
;################################################################################
;################################################################################
;push dword pointer to null terminated string. ebp + 16
;push dword colour code, formated 0x00:red:green:blue ebp+12
;push word x	ebp+10
;push word y	ebp+8
;registers used: eax,ecx,esi
;registers saved: esi
draw_string:
push ebp
mov ebp,esp

push esi

mov esi, [ebp + 16];lodsb pointer
mov ecx,[ebp+10];ecx = start x

cld;load forwards
.loop:
xor eax,eax ;clear eax
lodsb
test al,al
jz .end

push ecx
push dword [ebp+12]
push cx
push word [ebp+8]
push ax
call draw_char
pop ecx
add cx,8;next char position
jmp .loop
.end:
pop esi

leave
retn 12
