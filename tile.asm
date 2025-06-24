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
WaitForVBlank:
	ld A, [$FF44] ; LY
	cp 144
	jp c, WaitForVBlank

CopyTiles:
	nop

ActuallyCopyTiles:
	; Copy "Tiles" to VRAM, at $8000
	ld BC, CrossTile
	ld HL, $8000

NowBreakHere:
rept 15
	ld A, [BC]
	ld [HL+], A
	INC BC
endr

	ld A, [BC]
	ld [HL], A

SetupDisplayRegisters:
	ld A, %11_10_01_00
	ld [$FF47], A

	ld A, 64
	ld [$FF45], A
	ld A, %01000000
	ld [$FF41], A
	ld A, %00000010
	ld [$FFFF], A


;ScrollHorizontally:
;	ld A, %00000001 ; V-blank
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

SECTION "STAT handler", ROM0[$48]
ScanlineMadness:
	ld A, %11_00_00_00
	ld [$FF47], A

	ld A, 40
	ld [$FF43], A

	reti


SECTION "Tiles", ROM0[$500]
CrossTile:
	dw %00011000_00011000
	dw %00011000_00011000
	dw %00011000_00011000
	dw %10101010_01010101
	dw %10101010_01010101
	dw %00011000_00011000
	dw %00011000_00011000
	dw %00011000_00011000
CrossTileEnd:
