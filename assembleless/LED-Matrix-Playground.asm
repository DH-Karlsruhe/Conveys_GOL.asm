
init: 
        mov A, #0FFh            ; A <--Into--- #0FFh: A is pointer.
        mov R2, #00000001b      ; Setzt R2 auf 1
        clr c                   ; Clear Carry-Bit.
        mov R1, #1Fh            ; R1 <--Into--- #1Fh

start:
        inc R1
        rrc A           ; Rotate Accumulator Right Through Carry
        mov @R1, A      ; @(Pointer):R1 -> A
        mov p0, A       ; p0 <- A:    Schiebt Wert von A auch in p0
        xch A, R2       ; Exchange/Swap Values. <- Für Variablen-Tausch
        RL A            ; Rotate Accumulator Left
                        ;  => The left-most bit (bit 7) of the Accumulator is loaded into bit 0.
        mov p1, R2      ; p1 <- R2
        xch A, R2       ; Exchange Bytes: Accumulator -> Register
        cjne A, #00h, start     ; Compare and Jump If Not Equal
        jmp init