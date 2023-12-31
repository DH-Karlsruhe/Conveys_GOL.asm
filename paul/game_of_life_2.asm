; reset led matrix
mov	p0, #0h
mov	p1, #0h

; setting initial state of field
; ----------------------------
;mov	0x41, #01h
;mov	0x4A, #01h
;mov	0x50, #01h
;mov	0x51, #01h
;mov	0x52, #01h
include ../Conveys_GOL/BitmapInput.asm

; ----------------------------
start:
	call start_next_gen_calc
	call start_display
	jmp start
	;jmp end

; [START: next gen calc]------------------------------------------------------------------------------------------------------------------------
start_next_gen_calc:
	mov	R0, #40h			; start address of cells

loop_next_gen_calc:
	mov 	R7, #0h				; reset the border registry
	call	check_first_last_line
	call	check_first_last_column
	; R7 is a bitmap which contains the information, in which border the current cell is
	; 0000rlbt (Right, Left, Bottom, Top)
	call	check_top_left
	call	check_top
	call	check_top_right
	call	check_left
	call	check_right
	call	check_bottom_left
	call	check_bottom
	call	check_bottom_right

	inc	R0					; loop step
	cjne	R0, #080h, loop_next_gen_calc		; loop
ret
; [END: next gen calc  ]------------------------------------------------------------------------------------------------------------------------
top_wrap:
	mov	A, R7
	anl	A, #00000001b				; check if in first row
	cjne	A, #00000001b, not_top
	mov	A, R1
	add	A, #40h
	mov 	R1, A
	not_top:
	ret

bottom_wrap:
	mov	A, R7
	anl	A, #00000010b				; check if in first row
	cjne	A, #00000010b, not_bottom
	mov	A, R1
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #40h
	mov 	R1, A
	not_bottom:
	ret

left_wrap:
	mov	A, R7
	anl	A, #00000100b				; check if in first column
	cjne	A, #00000100b, not_left
	mov	A, R1
	add	A, #08h
	mov	R1, A
	not_left:
	ret

right_wrap:
	mov	A, R7
	anl	A, #00001000b				; check if in last column
	cjne	A, #00001000b, not_right
	mov	A, R1
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #08h
	mov	R1, A
	not_right:
	ret

check_top_left:
	mov	A, R0
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #09h					; substract 9 from address, but we have to write 08 here because the carry flag ist set (idk why)
	mov	R1, A
	call top_wrap
	call left_wrap
	call check_neighbor

	ret

check_top:
	mov	A, R0
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #08h
	mov	R1, A
	call top_wrap
	call check_neighbor
	ret

check_top_right:
	mov	A, R0
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #07h
	mov	R1, A
	call top_wrap
	call right_wrap
	call check_neighbor
	ret

check_left:
	mov	A, R0
	clr 	C					; clear the carry bit, so it does not mess up the subtraction
	subb	A, #01h
	mov	R1, A
	call left_wrap
	call check_neighbor
	ret

check_right:
	mov	A, R0
	add	A, #01h
	mov	R1, A
	call right_wrap
	call check_neighbor
	ret

check_bottom_left:
	mov	A, R0
	add	A, #07h
	mov	R1, A
	call bottom_wrap
	call left_wrap
	call check_neighbor
	ret

check_bottom:
	mov	A, R0
	add	A, #08h
	mov	R1, A
	call	bottom_wrap
	call check_neighbor
	ret

check_bottom_right:
	mov	A, R0
	add	A, #09h
	mov	R1, A
	call	bottom_wrap
	call	right_wrap
	call	check_neighbor
	ret

check_neighbor:
	mov	A, @R1
	anl	A, #00000001b
	cjne	A, #00000001b, neighbor_not_alive
	; when neighbor is alive, add 2 to the cell value
	mov	A, @R0
	add	A, #02h
	mov	@R0, A

	neighbor_not_alive:
	ret

; [START: display logic]------------------------------------------------------------------------------------------------------------------------
start_display:
	mov	R0, #040h			; start address of cells

	mov	R2, #01h			; column index
	mov	R3, #01h			; row index

	; reset led matrix
	mov	p0, #0h
	mov	p1, #0h

display_loop:
	call	update_cell
	mov	A, @R0				; load cell at R0 into A
	ANL	A, #01h				; and A with 01h
	cjne	A, #01h, after_led_panel_write	; if A is not equal to 01h, jump to after_write
	call	write_to_led_panel
after_led_panel_write:

	mov	A, R0				; load current address (in R0) into A
	ANL	A, #07h				; check if the lowest bits are all set
	cjne	A, #07h, loop_step		; if they are, goto loop_step

	call	shift_row_pointer			; shift the ROW pointer one to the left


loop_step:
	inc	R0				; increase address pointer
	call 	shift_col_pointer			; shift the COL pointer on to the left
	cjne	R0, #080h, display_loop		; loop

ret
; [END: display logic  ]------------------------------------------------------------------------------------------------------------------------

update_cell:
	mov	A, @R0
	anl	A, #00000001b			; check if cell was alive
	cjne	A, #00000001b, was_not_alive
	; was alive
	mov 	A, @R0
	rr	A
	anl	A, #01111111b			; ignore the rotated bit

	cjne	A, #02h, not_two_neighbors	; 2 neighbors
	jmp	cell_alive
	not_two_neighbors:
	cjne	A, #03h, cell_dead		; 3 neighbors
	jmp cell_alive

	was_not_alive:
	mov	A, @R0
	rr	A				; rotate to the left once
	cjne	A, #03h, cell_dead		; 3 neighbors
	jmp cell_alive

cell_alive:
	mov	@R0, #01h
	ret

cell_dead:
	mov	@R0, #00h
	ret

check_first_last_line:
; if R0 < 48 {
;   set R7 to 1		# we are in the first row
; } else if R0 > 77 {
;   set R7 to 2		# we are in the last row
; }
	; check if address is in first line
	cjne	R0, #48h, first_line_not_equal
	jmp	not_first_line
	first_line_not_equal:
		jc	first_line
		jmp	not_first_line
	first_line:
		mov	R7, #00000001b
		ret

	not_first_line:

		; check if address is in last line
		cjne	R0, #77h, last_line_not_equal
		jmp	not_last_line
	last_line_not_equal:
		jc	not_last_line
		jmp	last_line

	last_line:
		mov	R7, #00000010b
		ret

	not_last_line:
	ret

check_first_last_column:
; if R0 & 111 == 0 {
;   R7 += 4
; } else if R0 & 111 == 111 {
;   R7 += 8
; }
	; check if address is in first column
	MOV	A, R0
	ANL	A, #07h				; check if the lowest 3 bits are set
	cjne	A, #0h, not_first_column
	; first_column
	mov 	A, R7
	add	A, #00000100b
	mov	R7, A
	ret
	not_first_column:
		cjne	A, #07h, not_first_or_last_column
		; last_column
		mov 	A, R7
		add	A, #00001000b
		mov	R7, A
		ret
	not_first_or_last_column:
		ret

shift_row_pointer:
	mov	A, R3
	rl 	A
	mov 	R3, A
	ret

shift_col_pointer:
	mov	A, R2
	rl	A
	mov	R2, A
	ret

write_to_led_panel:
	mov	p1, R2
	mov	p0, R3
	mov	p1, #0h
	mov	p0, #0h
	ret

END: