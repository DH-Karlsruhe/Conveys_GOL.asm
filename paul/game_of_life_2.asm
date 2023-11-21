mov R0, #040h		; start address of cells

mov R1, #01h		; column index
mov R2, #01h		; row index

; reset led matrix
mov p0, #0h
mov p1, #0h
; ----------------------------
mov 0x49, #01h
mov 0x4A, #01h
mov 0x4B, #01h
; ----------------------------

loop:

mov A, @R0
ANL A, #01h
cjne A, #01h, after_write

jmp write_to_led_panel
after_write:

mov A, R0
ANL A, #07h		; check if the lowest bits are all set
cjne A, #07h, loop_step	; if they are, goto loop_step

; shift the ROW pointer one to the left
mov A, R2
rl A
mov R2, A

loop_step:
inc R0			; increase address pointer

; shift the COL pointer on to the left
mov A, R1
rl A
mov R1, A

cjne R0, #080h, loop	; loop

write_to_led_panel:
mov p1, R1
mov p0, R2
mov p1, #0h
mov p0, #0h
jmp after_write