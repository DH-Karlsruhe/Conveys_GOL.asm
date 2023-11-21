
init:
        MOV A,  #00000000b   ; Temporärer A-Speicher für Mapping
        MOV B, #00h          ; Temporäret B-Speicher für Mapping
        MOV R7, #00h         ; Reset auf erste Position in Eingabe-Bitmap
        MOV R6, #7Fh         ; Reset auf erste Position in Programm-Map
        jmp stepRow


stepRow:
        ; TODO: JMP out if out of bounds.
        MOV B, R7        ;
        MOV R6, B        ;
        
        MOV A, R7         ; Get current Row-Pointer into Acc.
        ADD A, #20h       ; Step to next Row (TODO: Validation?!)
        MOV R7, A         ; Copy new Row Value into Row-Pointer.
        