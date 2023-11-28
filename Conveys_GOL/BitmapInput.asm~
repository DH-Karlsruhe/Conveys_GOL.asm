; Doku mit Beispielen:  https://www.engineersgarage.com/8051-instruction-set/
; MOV (into) ## (from) ##

; # Value Comparison on MCU-8051
;CJNE  R0,#00H,NOTEQUAL
;; equal code goes here, then branch out
;NOTEQUAL:
;JC GREATER
;; less than code goes here, then branch out
;GREATER:
;; greater code goes here


init:
	MOV	A, #00000000b	; nur Acc kann zum arithmetieren verwendet werden! (ADD B, #20h  ; funkt nich.)
	MOV	R0, #00h	; Reset auf erste Position in Eingabe-Bitmap
	;
	MOV	R1, #7Fh	; Reset auf erste Position in Programm-Map
	MOV     R5, #0Fh        ; #0Fh = Active on lower half 
	                        ; | #F0h = Active on upper half
	MOV	R6, #00h	; Column-Count-Speicher für Mapping
        MOV     R7, #00h        ; Row-Count-Speicher für Mapping
	; R6 Step: 07h,27h,47h,67h, (upper-half) 0F,2F,4F,6F
	; 1.Option: Heraubstufende less-tham 07h<27h<47h => sieht nicht gut aus.
	; 2.Option: Arithmetisch mittels Incr. Col-Counter, 
	;           der bei ersten vier Reihen bei 07h abgefangen 
	;           und in nächster Reihe auf 00h zurückgesetzt wird.
	;           Bei den nächsten vier Reihen ändert sich der Zählbereich
	;           des Spaltenzählers auf den Intervall: [08h,0Fh]
	; 
	;           Zeiger-Wert wird durch Addition des Reihenwerts mit Spaltenwerts ermittelt.
	MOV	R7, #00h	; Reset des Row-Counters
	JMP	checkMapBounds

checkMapBounds:
	CJNE	R1, #40h, stepMap
	;  => Beende Initialisierung, wenn 0x40 in Programm-Map erreicht.
	JMP	isDone

stepMap:
	MOV	B, @R0		; Get Bit-Value of Input-Field
        ; ERROR: TODO: You cannot read bit-address of *bit addressable area*!
        ;              Use Registers & indizes (+complexity)
	JB	B.R0, setTargetBit	; Jump to set target bit if Input-Bit is set.
	JMP	nextInputVal
	DEC	R1		; Programm-Pointer muss nur dekrementiert werden.
	JMP	checkMapBounds  ; LOOP

nextInputVal:
        ; R0 is input Ptr-Store
        ; Before returning: Check if Accumulater is in bounds!
        ; R5 is the upper(F0)/lower(0F) switch
        CJNE    R5, #0Fh, nextUpperInputVal  ; means the opposite due to CJNE negation!
        CJNE    R5, #11110000b, nextLowerInputVal
	; differenciate upper and lower half of bit-map..
	JMP     nextInputRow
	; Column-Counter: [0,7]
	RET

nextLowerInputVal:
        CJNE	R6, #07h, nextInputCol    ; Also Resets Column counter!
        ; You are on last column of row here..
        ; [0,*7*]
        ; Are we still in lower half? => R7 == #67h => last field of lower half.
        ;         => if last field, switch R5 to upper-half(#F0h)
        ; TODO

nextUpperInputVal:
        CJNE    R6, #0Fh, nextInputCol
        ; You are on last column of row here..
        ; [8,*F*]
        ; TODO

nextInputCol:
        ; You are on [0,n-1] col.
        ;JC GREATER ; SHOULD NOT Happen as long as we use INC on a per loop basis!
        MOV    A, R7   ; Move row count in Acc
        ADD    A, R6   ; Add Col count 
        MOV    R0, A   ; Move new Pointer into input Pointer.

nextInputRow:
	; Row Incrementation is equal for upper/lower half.
	MOV	A, R0
	ADD	A, #20h		; Add 2 to upper nibble => Next input row.
	MOV	R0, A		; Put back into Input-Pointer.
	INC	R7		; Increment Row-Counter
	RET

setTargetBit:
	MOV	@R1, #01h	; Actually set Bit in target map.
	RET

isDone: ; ..CLEANUP..
	CLR	A
	MOV	B,  #00h
	MOV	R0, #00h
	MOV	R1, #00h
	MOV	R7, #00h
