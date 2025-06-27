DEF title  EQUS "AZULEJOS2" ; max 11 chars
DEF gameid EQUS "AZL2"      ; max  4 chars

SECTION "Header", ROM0[$100]
	di
	jp $150
	ds $134 - @, 0
	db "{title}"
	ds $13f - @, 0
	db "{gameid}"
	ds $150 - @, 0


DEF rSCY = $FF00+$42
DEF rSCX = $FF00+$43
DEF rLY  = $FF00+$44

SECTION "Entry point", ROM0[$150]

EntryPoint:
	; to fill
WaitForVBlank:
	ldh A, [$FF00+$44] ; LY
	cp 144
	jr nz, WaitForVBlank
	; Now it's safe to turn off the LCD
	ld HL, $FF40
	res 7, [HL]

CopyTiles:
	ld C, MyBGTiles.end - MyBGTiles
	ld HL, MyBGTiles
	ld DE, vMyBGTiles
.loop:
	ld A, [HL+]
	ld [DE], A
	inc DE
    dec C
	jr nz, .loop

SetupTilemap:
	ld HL, $9800  ; The start of the 1st tilemap
	ld A, $50
	ld C, 32      ; Keep track of whether we are starting a new row
.loop:
	xor 1         ; Toggle A between $50 and $51
:	ld [HL+], A   ; Write  $50 or $51 to the tile index pointed by HL and inc HL
	; Check if we are at the end of a row
	dec C
	jr nz, .checkEndOfTilemap0
	ld C, 32
	xor 1         ; we XOR again at the end of a row to get a checkered pattern
.checkEndOfTilemap0:
	bit 2, H      ; Becomes 1 when HL reaches $9C00
	jr z, .loop

SetupDisplayRegisters:
	ld A, %11_10_01_00 :: ldh [$FF47], A  ; BGP
	ld A, %00001000    :: ldh [$FF41], A  ; Select HBlank for STAT interrupt
	ld A, %00000011    :: ldh [$FFFF], A  ; enable VBlank and STAT interrupts

	; Turn LCD back on and enable interrupts
	ld HL, $FF40 :: set 7, [HL]
	ei

Done:
	halt
	jp Done


PUSHS "VBlank handler", ROM0[$40]
	jp DoTheScroll
POPS
DoTheScroll:
	;ldh A, [rSCY] :: inc A :: ldh [rSCY], A  ; SCY
	;ldh A, [rSCX] :: dec A :: ldh [rSCX], A  ; SCX
	ld A, [wCurScroll]
	inc A
	ld [wCurScroll], A
	ldh [rSCX], A
	sra A
	ldh [rSCY], A
	reti


PUSHS "STAT handler", ROM0[$48]
	jp ScanlineMadness
POPS
ScanlineMadness:
	; D = wCurScroll
	ld A, [wCurScroll]
	ld D, A
	; BC = rLY
	ld B, 0
	ld A, [rLY]
	ld C, A
	; HL = &tScanlineSine[rLY]
	ld HL, tScanlineSine
	add HL, BC
	; E = tScanlineSine[rLY] / 2^2
	ld A, [HL]
	REPT 2
		sra A
	ENDR
	ld E, A
	; Deform: rSCX = wCurScroll + tScanlineSine[rLY]
	ld A, D
	add A, E
	ld [rSCX], A
	REPT 2
		sra A
	ENDR
	ld [rSCY], A
	; Re-enable STAT interrupt
	ld A, %00000011 
	ldh [$FFFF], A
	reti


SECTION "Some tables", ROM0[$1000]
tScanlineSine:
 ; Generate a table of 144 sine values
 ; from sin(0.0 turns) to sin(1.0 turn) excluded,
 ; with amplitude scaled from [-1.0, 1.0] to [0.0, 128.0].
 DEF _freq = 2.0
 FOR angle, 0.0, 1.0, 1.0 / 144
     db MUL(SIN(MUL(_freq, angle)) + 1.0, 128.0 / 2) >> 16
 ENDR
 .end:


SECTION "My background Tiles", ROM0[$500]
MyBGTiles:
	LOAD "My background tiles in VRAM", VRAM[$8500]
		vMyBGTiles:
		.Filled1:
			REPT 3
				dw `10110111
				dw `11011112
			ENDR
			dw `11111111
			dw `12121212
		.Filled2:
			REPT 3
				dw `22222222
				dw `22222321
			ENDR
			dw `22222222
			dw `21212121
		.end:
	ENDL
.end:
ENDSECTION


SECTION "Variables in WRAM", WRAM0
wCurScroll: db