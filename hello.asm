DEF title  EQUS "RABIOSQUE" ; max 11 chars
DEF gameid EQUS "RABO"      ; max  4 chars

SECTION "Header", ROM0[$100]
	nop
	jp $150
	ds $134 - @, 0
	db "{title}"  
	ds $13f - @, 0
	db "{gameid}"
	ds $150 - @, 0

MyCodeStart:
	; Setup Mode 1 interrupt
	; ld HL, $FF41    ; Addresss of the STAT register
	; ld [HL], %0010000  

	ld A, %00000001 ; Mode 1 int select
	ld [$FFFF], A

	; Now halt
	halt  ; or jp Done

MoveRightOnce:
	; Move window 5 pixels to the right
	ld A, [$FF43]  ; SCX
	ADD 5
	ld [$FF43], A

	jp MyCodeStart

Done:
	jp Done



; Interrupt handlers
SECTION "VBlank handler", ROM0[$40]
	reti
