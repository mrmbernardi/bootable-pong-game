sectorsToRead equ 7

[BITS 16]	;Tells the assembler that its a 16 bit code
[ORG 0x7C00]	;Origin, tell the assembler that where the code will
				;be in memory after it is been loaded

;make sure the cs segment is what the assembler expects it to be
jmp 0x00:boot_start
boot_start:
;GET VBE CONTROLLER INFO (TO GET A MODE LIST)
mov ax, 0x7E00
mov es,ax   ;es di points to the struct.
xor di,di   ;set di to zero to point at 0x10000 the kernel will be loaded there later, so to get the LFB we are gonna store it in ecx
mov ax,0x4F00
int 10h


;Getting the right VBE mode.
mov si, [es:14]
mov ds, [es:16]
;ds:si = pointer to vbe mode list.

vbe_checkmodes:
xor di,di ;set di to zero so es:di points at 0x10000
mov ax,0x1000
mov es,ax

.loop:
mov cx,[ds:si]
cmp cx,0xFFFF
je fail ;we got to the end of the list and still nothing.
mov ax,0x4F01
int 10h ;call getmodeinfo

;LFB
mov ax,[es:0]
test ax,0x0080;test lfb bit
jz .next;if not LFB NEXT

;XRES
mov ax,[es:18];hopefully (if I counted right) the offset 18 should be XResolution
cmp ax,1024
jne .next 

;YRES
mov ax,[es:20];hopefully (if I counted right) the offset 20 should be YResolution
cmp ax,768
jne .next 

;BPP
xor ax,ax
mov al,[es:25];hopefully (if I counted right) the offset 25 should be the bits per pixel
cmp al,32	;32bpp
je .good
cmp al,24	;24bpp
je .good24

jmp .next
.good:
push word 0 ;push screen mode info
jmp .skip
.good24:
push word 1 ;push screen mode info
.skip:
;if we are here we got a good mode


push dword [es:28h] ;LFB for screen mode is at info struct + 28h
or cx,0x4000;set the LFB bit
mov bx,cx;the set mode int takes bx as the mode param.
jmp .end

.next:
add si,2
jmp .loop

.end:		

;SET GRAPHICS MODE
mov ax,4F02h
int 10h;set the mode.


;GET FONT POINTER
mov ax, 0x1130
mov bh, 0x6
push dx ;push drive number (we need it later for loading kernel)
int 10h
xor eax,eax
mov ax,es
shl eax,4
add ax,bp
pop dx ;pop drive number
push eax ;push the font pointer


;LOAD KERNEL TO 0x10000 physical (es=0x1000, bx=0)
mov ah,0x2 ;read sectors from memory
mov al,sectorsToRead ;number of sectors to read
mov ch,0 ;cylinder
mov cl,2 ;sector
mov dh,0 ;head
;mov dl,drivenumber (should already be set by BIOS)

;Where to put the data
mov bx, 0x1000
mov es, bx
xor bx,bx
;effective address is 0x10,000
int 0x13

;SWITCHING TO PROTECTED MODE:
cli
xor ax, ax
mov ds, ax ;ds = 0 needed for next command
lgdt [gdt_desc]   		; Load the GDT descriptor

mov eax, cr0            ; Copy the contents of CR0 into EAX
or eax, 1               ; Set bit 0
mov cr0, eax            ; Copy the contents of EAX into CR0

jmp 08h:clear_pipe		;jump to clear pipe to fix up the code segment register(using code segment 8h)

[BITS 32]
clear_pipe:				; fix up some more segment registers
mov ax, 10h             ; Save data segment identifyer
mov ds, ax              ; Move a valid data segment into the data segment register
mov ss, ax              ; Move a valid stack (i think) segment into the stack segment register
mov es, ax				; Move a valid extra segment thingy into extra segment

pop edx					;before we change the stack, we gotta take our font pointer off it.
pop ecx					;and the lfb
pop bx					;and the screen info (1 for 24bpp, 0 for 32bpp)


mov esp, 00090000h        ; Move the stack pointer to 090000h

jmp 0x10000 ;jump to kernel 
fail:
[BITS 16] ;16 bit boot failed code
mov ax,0xb800
mov ds,ax
mov byte [ds:0],'F'
mov byte [ds:1],0x04 ;red text
mov byte [ds:2],'A'
mov byte [ds:3],0x04
mov byte [ds:4],'I'
mov byte [ds:5],0x04
mov byte [ds:6],'L'
mov byte [ds:7],0x04
mov byte [ds:8],' '
mov byte [ds:9],0x04
jmp $
;this is the global descriptor table for 32 bit mode.
gdt:
gdt_null:
	dq 0
gdt_code:
	dw 0FFFFh ;limit 0FFFFh is as high as possible
	dw 0;base
	db 0;base again
	db 10011010b ;lower 4 = type bits, upper four = data or code segment, privilege level, present
	db 11001111b ;lower 4 = last bit in limit, bit 6 = 32bit or not, bit 7 = Granularity,If this bit is set, the limiter multiplies the segment limit by 4 kB. Bits 4 and 5 are pointless.
	db 0;base AGAIN!
gdt_data:
	dw 0FFFFh
	dw 0
	db 0
	db 10010010b
	db 11001111b
	db 0
gdt_end:

gdt_desc:                       ; The GDT descriptor
        dw gdt_end - gdt - 1    ; Limit (size)
        dd gdt                  ; Address of the GDT

TIMES 510 - ($ - $$) db 0	;Fill the rest of sector with 0
DW 0xAA55			;Add boot signature at the end of bootloader

;$ stands for start of the instruction
;$$ stands for start of the program
