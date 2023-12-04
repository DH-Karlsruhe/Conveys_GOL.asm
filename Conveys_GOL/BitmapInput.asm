; Doku mit Beispielen:  https://www.engineersgarage.com/8051-instruction-set/
; MOV (into) ## (from) ##

; # Value Comparison on MCU-8051
;CJNE  R0,#00H,NOTEQUAL
;; equal code goes here, then branch out
;NOTEQUAL:
;JC LESS_THAN
;; greater than code goes here, then branch out
;LESS_THAN:
;; less than code goes here
;
; RR A  ; Rotiert um ein Bit nach Rechts, 
	; sodass diese rechts (LSB) in das Carry-Bit fallen
	; und beim nächsten Mal rotieren wieder ans linke (MSB) Bit geschrieben werden.
;
;  <symbol> SET <register> funktioniert nicht mit CJNE!
;


init:
	;CALL	loadGliderPreset
	MOV	A, #00000000b	; nur Acc kann zum arithmetieren verwendet werden! (ADD B, #20h  ; funkt nich.)
	MOV	R0, #20h	; Reset to first Byte-Position of Input-Bitmap
	;
	MOV	R1, #7Fh	; Reset auf erste Position in Programm-Map
	; --
	MOV	R5, #0Fh	; #0Fh = Active on lower half | #F0h = Active on upper half
	MOV	R6, #00h	; Column-Count-Speicher für Mapping [0,7]
	MOV	R7, #00h	; Row-Count-Speicher für Mapping
	CLR	P		; Clear Parity-Bit
	; R6 Step: 07h,27h,47h,67h, (upper-half) 0F,2F,4F,6F
	; 1.Option: Heraubstufende less-tham 07h<27h<47h => sieht nicht gut aus.
	; 2.Option: Arithmetisch mittels Incr. Col-Counter, 
	;           der bei ersten vier Reihen bei 07h abgefangen 
	;           und in nächster Reihe auf 00h zurückgesetzt wird.
	;           Bei den nächsten vier Reihen ändert sich der Zählbereich
	;           des Spaltenzählers auf den Intervall: [08h,0Fh]
	;            => Zeiger-Wert wird durch Addition des Reihenwerts mit Spaltenwerts ermittelt.
	; 3.Option: Da es nicht möglich ist Bit-Zeiger zu arithmetieren
	;           und nur statisch auf die Indizes zugegriffen werden kann,
	;           wird zeilenweise (byte-weise) eingelesen
	;           und jedes Bit per Index überprüft, was im 1-Fall zu einem Setzen in der Programm-Map führt.
	MOV	R7, #00h	; Reset des Row-Counters
	;CALL    resetProgrammMap
	JMP	checkMapBounds

checkMapBounds:
	CJNE	R1, #3Fh, checkLessThanBounds
	;  => Beende Initialisierung, wenn 0x3F (Folge-Stelle der letzten Zelle) in Programm-Map-Pointer erreicht. (wird nur dekrementiert)
	JMP	isDone

checkLessThanBounds:
	JC	isDone		; less than boundary - which is possible in some cases.
	JMP	stepRow

stepRow:
	MOV	A, @R0		; Get Row-Byte-Value of Input-Row
	JMP	stepCol

stepCol:
	; Check if Boundary is reached
	CJNE	R6, #08h, evalCell
	; Boundary reached..
	MOV	R6, #00h	; Reset Col-Counter
	CALL	nextInputRow
	JMP	checkMapBounds	; LOOP-Row

evalCell:
	JB	A.0, setTargetBit	; Jump to set target bit if Input-Bit is set.
	CALL	nextMapStep
	JMP	stepCol

nextMapStep:			; only call with CALL!
	DEC	R1		; Programm-Pointer-- ()only has to be decremented)
	INC	R6		; Col-Counter++
	RR	A		; rotate >> bit in scope of A.0
	RET

nextInputRow:			; only call with CALL!
	; Row Incrementation is equal for upper/lower half.
	CJNE	R7, #03, stepInputRow
	MOV	R0, #21h	; Switch to new Memory-Location for upper half
	MOV	R6, #00h	; Reset Col-Counter
	INC	R7		; Row-Counter (although its trivial at this point)
	RET

stepInputRow:
	MOV	A, R0
	ADD	A, #04h		; Add 4 to upper nibble => Next LOWER-HALF input row.
	MOV	R0, A		; Put back into **Input-Pointer**.
	INC	R7		; Increment Row-Counter (to switch to upper half if = 4)
	RET

setTargetBit:
	MOV	@R1, #01h	; Actually set Bit in target map.
	CALL	nextMapStep
	JMP	stepCol

resetProgrammMap:
	CJNE	R1, #3Fh, resetProgrammMapStep
	MOV	R7, #00h
	RET

resetProgrammMapStep:
	DEC	R1
	MOV	@R1, #00h	; Reset Cell
	JMP	resetProgrammMap

; STUPID: Due 8-Bit relative addressable BUG,
;         this label "isDone" cannot be at the bottom,
;         because its called too far ahed?!?!
isDone:				; ..CLEANUP..
	CLR	A
	MOV	B, #00h
	MOV	R0, #00h
	MOV	R1, #00h
	MOV	R7, #00h
	JMP     FIN
	; FIN. => Play..

;;;;;;;;;;;;;;
; OPTIONALS
loadPreset:
        ; bottom up with R0 => R7
	MOV	A, R0
	MOV	B, R1
	MOV	R0, #20h	; lowest line.
	MOV	R1, #24h	; 2. line (bottom up)
	MOV	@R0, A
	MOV	@R1, B
	MOV	A, R2
	MOV	B, R3
	MOV	R0, #28h	; 3. line
	MOV	R1, #2Ch	; 4. line
	MOV	@R0, A
	MOV	@R1, B
	MOV	A, R4
	MOV	B, R5
	MOV	R0, #21h	; 5. line
	MOV	R1, #25h	; 6. line
	MOV	@R0, A
	MOV	@R1, B
	MOV	A, R6
	MOV	B, R7
	MOV	R0, #29h	; 5. line
	MOV	R1, #2Dh	; 6. line
	MOV	@R0, A
	MOV	@R1, B
	; Clear All registers
	MOV	R7, #00000000b
	MOV	R6, #00000000b
	MOV	R5, #00000000b
	MOV	R4, #00000000b
	MOV	R2, #00000000b
	MOV	R1, #00000000b
	MOV	R0, #00000000b
	RET

; PRESETS
loadGliderPreset:
	MOV	R7, #01000000b
	MOV	R6, #00100000b
	MOV	R5, #11100000b
	MOV	R4, #00000000b
	MOV	R2, #00000000b
	MOV	R1, #00000000b
	MOV	R0, #00000000b
	CALL	loadPreset
	RET



; HAS TO BE @END!

FIN: 