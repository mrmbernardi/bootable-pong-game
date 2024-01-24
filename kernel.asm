;CONSTANTS HERE!
video_width equ 1024
video_height equ 768
video_byte_depth equ 4
video_length equ video_width * video_height * video_byte_depth
video_dword_length equ video_length / 4

font_char_length equ 16

paddle_width equ 20
paddle_height equ 100
paddle_y_limit equ video_height - paddle_height

ball_radius equ 5
ball_start_x equ __float32__(507.0);floating point for half the video width - 5 (ball radius). nasm will not calculate floats so you have to write the exact number down
ball_start_y equ __float32__(379.0);same as above except for video height
ball_start_speedx equ __float32__(-10.0)
ball_start_speedy equ __float32__(0.0)
ball_paddle_left equ __float32__(20.0);the x of the ball if it's against the left paddle
ball_paddle_right equ __float32__(994.0);the x of the ball if it's against the right paddle
ball_screen_right equ __float32__(1014.0);the x of the ball if it was against the right of the screen
ball_screen_bottom equ __float32__(758.0);the y of the ball if it was against the bottom of the screen
ball_y_bounce_divisor equ __float32__(8.0);controls how much of an angle the ball comes off the paddle off when it hits the edge.

;THIS IS AT 0x10000
[ORG 0x10000]	;Origin, tell the assembler that where the code will be
[BITS 32]
kernel_start:
call initialise

main_loop:
call update
call draw

stay_stopped:
hlt
mov eax,[MS_COUNT]
cmp eax,33; ~30 fps
jbe stay_stopped
mov dword [MS_COUNT], 0
mov dword [MS_COUNT + 4], 0

jmp main_loop; infinite loop

title_text:
db 'Press any key to start and press escape to reset.',0
score_text:
db 'Score: '
score_num_text:
db 0,0,0,0,0,0,0,0,0,0,0 ;text for displaying score

text24bit:
db '24bpp mode',0
text_rev:
db 'Revision: 1',0
;FUNCTIONS HERE
%include "draw_functions.asm"
%include "functions.asm"

;INTERRUPTS HERE
%include "interrupts.asm"

;####################
;DATA IS STORED HERE!
LFB: dd 0 ;Pointer to linear frame buffer;idt+2048 to leave room for a full IDT
DRAWFB: dd 0 ;Pointer to frame buffer
SCREENMODE: db 0;The way this works is it holds 0 if screen mode is 32bpp, else screen mode is 24 bpp
FONT_PTR: dd 0 + 4;Pointer to BIOS font
MS_COUNT: dq 0 ;64 bit 32.32 fixed point millisecond count (for frame rate) first dword is integer second dword is fraction
KEYS_PRESSED: db 0 ;Byte, the way this works is bits are set according to the keys currently pressed: bit 0 = Up key, bit 1 = Down key, bit 2 = Left key, bit 0 = Right key. Bit 7 is if a key has been pressed.
PADDLE1_POS: dd (video_height/2) - (paddle_height/2);dword, describing Y position of the left top of paddle
PADDLE2_POS: dd (video_height/2) - (paddle_height/2);dword, describing Y position of the left top of paddle
BALLX: dd ball_start_x;dword float. position of the top left of the ball.
BALLY: dd ball_start_y;dword float. position of the top left of the ball.
BALLSPEEDX: dd ball_start_speedx ;dword float. speed of the ball
BALLSPEEDY: dd ball_start_speedy ;dword float speed of the ball
PADDLE1_SCORE: dd 0 ;dword left paddle score
PADDLE2_SCORE: dd 0 ;dword right paddle score

align 512
