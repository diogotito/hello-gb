DEF title  EQUS "AZULEJOS" ; max 11 chars
DEF gameid EQUS "AZUL"     ; max  4 chars

SECTION "Header", ROM0[$100]
	nop
	jp $150
	ds $134 - @, 0
	db "{title}"  
	ds $13f - @, 0
	db "{gameid}"
	ds $150 - @, 0

CopyTiles:
	; Copy "Tiles" to VRAM, at $8000
	ld BC, CrossTile
	ld HL, $8000

	ld A, [BC]  ; 0x156
	ld [HL+], A
	INC BC

	ld A, [BC]
	ld [HL+], A
	INC BC

	ld A, [BC]
	ld [HL+], A
	INC BC

	ld A, [BC]
	ld [HL+], A
	INC BC

	ld A, [BC]
	ld [HL+], A
	INC BC

	ld A, [BC]
	ld [HL+], A
	INC BC

	; ld A, [BC]
	; ld [HL+], A
	; INC BC

	; ld A, [BC]
	; ld [HL+], A


;ScrollHorizontally:
;	ld A, %00000001 ; Mode 1 int select
;	ld [$FFFF], A
;
;	; Now halt
;	halt  ; or jp Done
;
;MoveRightOnce:
;	; Move window 5 pixels to the right
;	ld A, [$FF43]  ; SCX
;	ADD 5
;	ld [$FF43], A
;
;	jp ScrollHorizontally

Done:
	jp Done



; Interrupt handlers
SECTION "VBlank handler", ROM0[$40]
	reti


SECTION "Tiles", ROM0[$300]
CrossTile:
	dw %00011000_00011000
	dw %00011000_00011000
	dw %00011000_00011000
	dw %11111111_11111111
	dw %11111111_11111111
	dw %00011000_00011000
	dw %00011000_00011000
	dw %00011000_00011000
CrossTileEnd:
