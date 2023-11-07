;--------------------Game of live - --------------------
;
; Vorlesung: 	Systemname Programmierung
; Von:		Jennifer, Thomas und Alexander
; https://de.wikipedia.org/wiki/Conways_Spiel_des_Lebens
;
;
; Dauer New_Generation: 11,423ms

; -----------------
; Startpunkt
;------------------
	cseg	at 0h
	ajmp	init		;Überspringe interrupts und gehe zur initialisierung
	cseg	at 100h

; -----------------
; Interrupt Timer 0
;------------------
	ORG	0bh		;Einsprung Adresse für TF0
	call	setTimer0	;Setzen des Startwertes von Timer0 (Da 16Bit kein automatischer reload!)
	call	timer0Routine	;Springe zur routine für Timer0
	reti			;Springe zur Stelle im Code vor dem Interrupt

; -----------------
; Interrupt timer 1
;------------------
	ORG	1bh
	call	setTimer1	;Setzen des Startwertes von Timer1 (Da 16Bit kein automatischer reload!)
	MOV	40, #0fh	;	;Setze Speicher an Stelle 40 auf #0Fh (TODO Richtiger Merker wäre besser)
	reti			;Springe zur Stelle im Code vor dem Interrupt

;------------------
;init
;------------------
	ORG	50h
init:
	call	initCanvas

	mov	IE, #10001010b	;Setze EA, ET0, ET1 um die Timer einzustellen
	mov	tmod, #00010001b	;Setze timer modus für T0 und T1 auf 16Bit

	call	setTimer0	;Setze Startwerte für T0
	SETB	TR0		;Starte T0
	call	setTimer1	;Setze Startwerte für T1
	SETB	TR1		;Starte T1

	call	display

	call	main

;------------------
;main (loop)
;------------------
main:
	MOV	A, 40		;Lade byte welches von T1 gesetzt wird in Akku
	JZ	main		;Wenn es null versuche es nochmal
	MOV	40, #0		;Sonst setze es auf null...
	call	NEW_GENERATION	;...und berechne die neue Generation
	jmp	main		;Danach wieder von vorne

;------------------
;Rücksetzten der Timer
;------------------
setTimer0:
	mov	tl0, #000h	;Setzen des niederwertigen start bytes von T0
	mov	th0, #0fdh	;Setzen des höherwertigen start bytes von T0
	SETB	TR0		;Starte Timer 0
	ret

setTimer1:
	mov	tl1, #068h	;Setzen des niederwertigen start bytes von T1
	mov	th1, #0C5h	;Setzen des höherwertigen start bytes von T1
	SETB	TR1		;Starte Timer 1
	ret

;----------------------
; timer0 inerrupt routine
;----------------------
timer0Routine:
	push	00h		;Speichern von R0 auf dem Stack, damit dieser nach der Interrupt routine wieder zurück gesetzt werden kann
	push	01h		;Speichern von R1
	push	ACC		;Das gleiche für den Akku
	call	display		;Einmal das Spielfeld zeichnen
	pop	ACC		;Rücksetzten von A aus dem Stack
	pop	01h
	pop	00h		;Das gleiche für R0
	ret

;----------------------
; Logik für die neue Generation
;----------------------
new_generation:
	MOV	R2, #0		;Zeilen Zähler (0-7)

checkrow:			;Iteriert durch alle Zeilen
	MOV	R3, #0		;Spalten Zähler (0-7)
	MOV	R4, #0		;R4 ist ein Zwischenspeicher für die neue Zeile
	MOV	R1, #0		;TODO

checkcolumn:			;Iteriert durch alle Spalten
	MOV	R7, #0		;Zurücksetzen von R7 (Speichert die anzahl an Nachbarn einer Zelle zwischen)
	mov	DPTR, #table2	;Laden der Masken für die Nachbar-Checks
	ACALL	checkTop	;Überprüfen wie viele Nachbarn in der Zeile oberhalb der Zelle sind
	ACALL	checkMid	;Überprüfen wie viele Nachbarn in der Zeile der Zelle sind
	ACALL	checkBottom	;Überprüfen wie viele Nachbarn in der Zeile unterhalb der Zelle sind

	mov	DPTR, #table	;Setze DataPointer auf masken tabelle für das hinzufügen der neuen Zelle
	mov	A, R3		;Lade die aktuelle Spaltennummer
	movC	A, @A+DPTR	;Hole Maske dass nur die Spalte gesetzt wird (z.B. Maske Spalte 0: #10000000b, Maske Spalte 5: #00000100b, usw.)
	mov	R6, A		;		;Zwischenspeichern des Maske in R6

	MOV	A, R2		;		;Kopiere aktuelle Zeile der Zelle in R0
	MOV	R0, A		;
	MOVX	A, @R0		;		;Lade Zeileninhalt aus Speicher
	MOV	R5, A		;		;Zwischenspeichern der Zeile in R5

	MOV	A, R7		;		;Hole die Anzahl an Nachbarn in den Akku zum vergleichen
	CJNE	A, #2, checkUnderPopulation	;Überprüfe ob es zwei Nachbarn sind, wenn nicht dann ob mehr oder weniger
	MOV	A, R6		;Wenn A = 2 -> Behalte Wert der Zelle bei und lade die in R6 zwischengespeicherte Maske
	ANL	A, R5		;Maskiere Wert der Zelle aus
	ORL	A, R1		;Und füge ihn zur neuen Zeile hinzu
	MOV	R1, A		;Speichere den Wert der aktualisierten, neuen Zeile zwischen
	JMP	checkEnd	;Die Überprüfung der Zelle ist zu Ende

checkUnderPopulation:		;Überprüfe ob eine Unterpopulation vorliegt und die Zelle an Einsamkeit stirbt
	JNC	checkPerfectPopulation	;Wenn A > 2, dann wurde das Carry bit durch CJNE auf 0 gesetzt -> Sprung zu checkPerfectPopulation
	JMP	checkEnd	;Sonst war es eine Unterpopulation und die Zelle stirbt (Wird nicht gesetzt) und die Überprüfung endet

checkPerfectPopulation:		;Überprüfe ob es genau 3 Nachbarn gibt und die Zelle reanimiert wird
	CJNE	A, #3, checkEnd	;Wenn A != 3 können es jetzt nur noch mehr sein -> Zelle stirbt (wird nicht gesetzt)
	MOV	A, R6		;Lade die in R6 gespeicherte Maske
	ANL	A, #11111111b	;Setze die Zelle durch die Maske an der entsprechenden Stelle auf 1
	ORL	A, R1		;Berechne neue Zeile
	MOV	R1, A		;Füge Wert zur neuen Zeile hinzu
	JMP	checkEnd	;Die Überprüfung endet hier

checkEnd:			;Sprungpunkt wenn die Überprüfungen enden
	INC	R3		;Die Nächste Spalte wird betrachtet
	MOV	A, R3		;Lade Spalten Nr. in Akku zum Vergleichen
	CJNE	A, #8, checkcolumn	;Wenn die Spalten Nr. 8 entspricht wurde die komplette Zeile bearbeitet und es findet KEIN Sprung zu "checkcolumn" statt


	MOV	A, R2		;		;Stattdessen wird der Zeilenzähler zum Vergleichen in den Akku geladen
	ADD	A, #100		;		;Und es wird 100 dazu addiert (Um sicherzugehen dass keine schon belegte Speicherstelle adressiert wird)
	MOV	R0, A		;		;Die Speicherstellen Adresse wird in R0 geschrieben
	MOV	A, R1		;		;Und der zu speichernde Inhalt (die neue Zeile) in den Akku kopiert
	MOVX	@R0, A		;		;Anschließend wird die Zeile in den Speicher geschreiben

	INC	R2		;Die Zeilen Nr. um ein erhöht
	MOV	A, R2		;und zu Vergleichszwecken un den Akku geschrieben
	CJNE	A, #8, checkrow	;Wenn die Zeilen Nr. 8 entspricht wurden alle Zeilen bearbeitet und die neue Generation ist fertig. Es findet KEIN Sprung zu "checkrow" statt

	call	copyNewGenerationToField	;Die neue Generation wird nun vom Zwischenspeicher auf das richtige Feld geladen
	ret			;Fertig, kehre zur Hauptschleife "main" zurück

;----------------------
; Logik zum ermitteln der Anzahl an Nachbarn in der selben Zeile, der oberhalb und der unterhalb der Zelle
;----------------------
checkTop:
	MOV	A, R2		;Lade Zeilen Nr.
	MOV	R0, #7		;		;Wenn Zeilen Nr. = 0 ist die unterstee Zeile die "darüber", da das Spielfeld sphärisch ist
	JZ	gotTopRow	;Falls Zeilen Nr. = 0 springe zu "gotTopRow" da keine weitere berechnung nötig
	DEC	A		;			;Falls nicht entspricht die Zeilen Nr. darüber der Nr. im Akku - 1
	MOV	R0, A		;		;Speichern der Zeilen Nr. in R5

gotTopRow:
	CALL	calculateNeighbours	;Berechne die Nachbarn für die Zeile
	ret			;Fertig

checkMid:
	MOV	A, R2		;		;Lade Zeilen Nr.
	MOV	R0, A		;		;Speicher Zeilen Nr. in R5 zwischen
	ACALL	calculateMiddleNeighbours	;Berechne die Nachbarn für die Mittlere Zeile (Eigene Zelle wird nicht addiert!)
	ret

checkBottom:
	MOV	A, R2		;		;Lade Zeilen Nr.
	MOV	R0, #0		;		;Wenn Zeilen Nr. = 7 ist die oberste Zeile die darunter, da das Spielfeld sphärisch ist
	CJNE	A, #7, getBottomRow
	JMP	gotBottomrow	;Wenn die Zeilen Nr. = 7 muss nichts mehr getan werden
getBottomRow:
	INC	A		;			;Wenn sie != 7 dann ist die untere Zeilen Nr. A - 1
	MOV	R0, A		;		;Speichern der Unteren Zeilen Nr. in R5
gotBottomRow:
	CALL	calculateNeighbours	;Berechne die Nachbarn für die Zeile
	ret

calculateNeighbours:
	MOVX	A, @R0		;		;Laden der entsprechenden Zeile
	MOV	R6, A		;Speichern der rotierten Zeile

	call	checkSideNeighbour	;Ermitteln ob die Seitlichen Nachbarn gesetzt sind
	call	checkMiddleNeighbour	;Ermitteln ob mittlerer Nachbar gesetzt ist
	ret

calculateMiddleNeighbours:
	MOVX	A, @R0		;		;Laden der entsprechenden Zeile
	MOV	R6, A		;Speichern der rotierten Zeile

	call	checkSideNeighbour	;Ermitteln ob die Seitlichen Nachbarn gesetzt sind
	ret


;----------------------
; Logik zum ermitteln der Nachbarn Rechts, Links und in der selben Spalte einer Zelle
;----------------------
checkSideNeighbour:
	MOV	A, R3		;Lade Spalten Nr. in R3
	MOVC	A, @A+DPTR	;Lade Maske für die Spalte A
	ANL	A, R6		;		;Ermittel den Zustand der Spalte mithilfe der Zeile R6
	JZ	rightCheckDone	;Wenn A = 0 war die Zelle nicht gesezt und das erhöhen des Nachbar Zählers wird übersprungen
	INC	R7		;			;Sonst: Erhöhen des Nachbarzählers
rightcheckdone:

	MOV	A, R3		;Lade Spalten Nr. in R3
	ADD	A, #2		;Erhöhe Spalten Nr. um zwei um den rechten Nachbarn auszumaskieren
	MOVC	A, @A+DPTR	;Lade Maske für die Spalte A
	ANL	A, R6		;		;Ermittel den Zustand der Spalte mithilfe der Zeile R6
	JZ	leftCheckDone	;Wenn A = 0 war die Zelle nicht gesezt und das erhöhen des Nachbar Zählers wird übersprungen
	INC	R7		;			;Sonst: Erhöhen des Nachbarzählers
leftCheckDone:

	ret			;Fertig -> Rücksprung

checkMiddleNeighbour:
	MOV	A, R3		;Lade Spalten Nr. in R3
	INC	A		;Erhöhe Spalten Nr. um eins um den mittleren Nachbarn auszumaskieren
	MOVC	A, @A+DPTR	;Lade Maske für die Spalte A
	ANL	A, R6		;		;Ermittel den Zustand der Spalte mithilfe der Zeile R6
	JZ	middleCheckDone	;Wenn A = 0 war die Zelle nicht gesezt und das erhöhen des Nachbar Zählers wird übersprungen
	INC	R7		;			;Sonst: Erhöhen des Nachbarzählers
middleCheckDone:

	ret			;Fertig -> Rücksprung

;----------------------
; Kopieren der neuen Generation auf die Speicherstellen welche welche gezeichnet werden
;----------------------
copyNewGenerationToField:
	MOV	R0, #100
	MOV	R1, #0
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #101
	MOV	R1, #1
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #102
	MOV	R1, #2
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #103
	MOV	R1, #3
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #104
	MOV	R1, #4
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #105
	MOV	R1, #5
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #106
	MOV	R1, #6
	MOVX	A, @R0
	MOVX	@R1, A

	MOV	R0, #107
	MOV	R1, #7
	MOVX	A, @R0
	MOVX	@R1, A

	ret

;----------------------
; Zeichen der Speicher stelle 0h bis 7h auf die LED-Matrix
;----------------------
display:
	mov	R0, #0h
	mov	R1, #00000001b

	mov	A, #0

zeichneNaechsteReihe:
	call	displayRow

	inc	A
	cjne	A, #8, zeichneNaechsteReihe
	ret

;----------------------
; Zeichen der Aktuellen Zeile
;----------------------
displayRow:
	push	A
	movx	A, @R0
	mov	P3, R1
	mov	P2, a
	mov	P2, #0

	inc	R0
	MOV	A, R1
	RL	A
	MOV	R1, A
	pop	A
	ret

;----------------------
; Nutzereingabe für das Spielfeld
;----------------------
initCanvas:
	MOV	R0, #0		;				;Zeilen zähler
	MOV	P3, #00000001	;

getNextRowInput:
waitForConfirmation:
	MOV	A, P0		;
	ANL	A, #00000001b
	jnz	waitForConfirmation	;Warte bis P0.0 gedrückt wurde
waitForConfirmationButtonRelease:
	MOV	A, P0		;
	ANL	A, #00000001b
	jz	waitForConfirmationButtonRelease	;Warte bis P0.0 "Losgelassen" wurde

	MOV	A, P1		;Zeile 0 in Akku
	CPL	A
	movx	@R0, A		;Speichern

	mov	P2, A		;LEDs an
	mov	P2, #0		;LEDs aus

	mov	a, P3		;Zeilenmaske laden
	RL	A		;Maske für die nächste Zeile erstellen
	mov	p3, a		;Maske an p3 ausgeben
	inc	R0		;Zeilenzähler erhöhen

	cjne	R0, #8, getNextRowInput	;Wenn alle acht zeilen gezeichnet sind wird weiter gemacht

	ret

; -----------------
; Masken
;------------------
table:	db	10000000b, 01000000b, 00100000b, 00010000b, 00001000b, 00000100b, 00000010b, 00000001b
table2:	db	00000001b, 10000000b, 01000000b, 00100000b, 00010000b, 00001000b, 00000100b, 00000010b, 00000001b, 10000000b

	end