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
	ld a, 40 :: ldh [hMetaspriteX], a
	ld a, 80 :: ldh [hMetaspriteY], a
	ld a, 1 :: ldh [hMetaspriteVX], a
	ld a, 1 :: ldh [hMetaspriteVY], a
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

CopyOBJs:
	ld C, MyOAMentries.end - MyOAMentries
	ld HL, MyOAMentries
	ld DE, inOAM
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
	ld [HL+], A   ; Write  $50 or $51 to the tile index pointed by HL and inc HL
	; Check if we are at the end of a row
	dec C
	jr nz, .checkEndOfTilemap0
	ld C, 32
	xor 1         ; we XOR again at the end of a row to get a checkered pattern
.checkEndOfTilemap0:
	bit 2, H      ; Becomes 1 when HL reaches $9C00
	jr z, .loop

IF !DEF(SkipCartridgeHeaderLogoCopy)
	; Repeat bootrom logic of decompressing the logo from the cartridge header to
	; VRAM, so that it shows up in my GBA
	; Adapted from https://github.com/ISSOtm/gb-bootroms/blob/master/src/dmg.asm
		ld DE, $0104  ; header logo
		ld hl, $8010  ; logo tiles in VRAM
	.decompressLogo
		ld a, [de]
		call DecompressFirstNibble
		call DecompressSecondNibble
		inc de
		ld a, e
		cp $34
		jr nz, .decompressLogo
		jp SetupDisplayRegisters  ; Skip over to my code
	DecompressFirstNibble:
		ld c, a
	DecompressSecondNibble:
		ld b, 8 / 2 ; Set all 8 bits of a, "consuming" 4 bits of c
	.loop
		push bc
		rl c ; Extract MSB of c
		rla ; Into LSB of a
		pop bc
		rl c ; Extract that same bit
		rla ; So that bit is inserted twice in a (= horizontally doubled)
		dec b
		jr nz, .loop
		ld [hli], a
		inc hl ; Skip second plane
		ld [hli], a ; Also double vertically
		inc hl
		ret
ENDC

; now back to my code
SetupDisplayRegisters:
	ld A, %11_10_01_00 :: ldh [$FF47], A  ; BGP
	ld A, %11_11_11_11 :: ldh [$FF48], A  ; OBP
	ld A, %00001000    :: ldh [$FF41], A  ; Select HBlank for STAT interrupt
	ld A, %00000011    :: ldh [$FFFF], A  ; enable VBlank and STAT interrupts
	ld A, %10010011    :: ldh [$FF40], A  ; Turn LCD back on and enable OBJ display
	ei

Done:
	halt
	jp Done


PUSHS "VBlank handler", ROM0[$40]
	jp DoTheScroll
POPS
DoTheScroll:
	ld A, [wCurScroll]
	inc A
	ld [wCurScroll], A
	ldh [rSCX], A
	sra A
	ldh [rSCY], A

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Nintendon't metasprite
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ei
	ld HL, inOAM.Nintendont
	ld C, (inOAM.end - inOAM.Nintendont) / 4
.loopOBJ
	; HL = &curOBJ->y
	ldh A, [hMetaspriteVY]
	ld B, A
	ld A, [HL]
	add B
	ld [HL+], A

	; HL = &curOBJ->x
	ldh A, [hMetaspriteVX]
	ld B, A
	ld A, [HL]
	add B
	ld [HL+], A

	; Skip over tile index and attributes
	inc HL
	inc HL

	; Loop to the next OBJ if we didn't reach the end
	dec C
	jr nz, .loopOBJ

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Bouncing logic
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
	macro obpSwap
		ld B, A
		ldh A, [$FF48]  ; OBP
		cpl
		ldh [$FF48], A
		ld A, B
	endm

	di

	; Y += VY
	ldh A, [hMetaspriteVY]
	ld B, A
	ldh A, [hMetaspriteY]
	add B
	ldh [hMetaspriteY], A

	; if (Y <= 16) VY = 1
	cp 16 + 1
	jr !c, :+
	ld A, 1
	ldh [hMetaspriteVY], A
	obpSwap

	; if (Y => 128) VY = -1
:	cp 128 + 1
	jr c, :+
	ld A, -1
	ldh [hMetaspriteVY], A
	obpSwap

	; X += VX
:	ldh A, [hMetaspriteVX]
	ld B, A
	ldh A, [hMetaspriteX]
	add B
	ldh [hMetaspriteX], A

	; if (X <= 8) VX = 1
	cp 8 + 1
	jr !c, :+
	ld A, 1
	ldh [hMetaspriteVX], A
	obpSwap

	; if (X => 102) VX = -1
:	cp 102 + 1
	jr c, :+
	ld A, -1
	ldh [hMetaspriteVX], A
	obpSwap

:	reti


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


SECTION "Hardcoded OAM entries", ROM0[$800]
MyOAMentries:
	LOAD "My entries copied to OAM", OAM[$FE00]
		inOAM:
		; Byte 0 - Y Position + 16
		; Byte 1 - X Position + 8 
		; Byte 2 - Tile index (unsigned)
		; Byte 3 - Attributes/Flags:
		;            Priority (0 = normal) | Y flip | X flip | OBP0 or 1 | x | xxx
		macro moveTo
			def curX = \1
			def curY = \2
		endm
		macro putOBJ
			db curY, curX, \1, %00000000
			def curX += 8
		endm
		.Nintendont:
			moveTo 40, 16 + (8*8)
			for tile_index, $01, $0A
				putOBJ tile_index
			endr
			moveTo 40, 16 + (8*8) + 8
			for tile_index, $0D, $16
				putOBJ tile_index
			endr
			moveTo 46, 16 + (8*10 + 1)
			putOBJ $0A
			putOBJ $0B
			putOBJ $0C
			def curX -= 2
			putOBJ $05
			def curX += 2
			putOBJ $04
			putOBJ $05
			putOBJ $06
			moveTo 46, 16 + (8*10 + 1) + 8
			putOBJ $16
			putOBJ $17
			putOBJ $18
			def curX += 8
			putOBJ $10
			putOBJ $11
			def curX += 2
			def curY -= 2
			db curY, curX, $19, %01110000
		.end: ds $FEA0 - @, 0
	ENDL
.end:

SECTION "My background Tiles", ROM0[$500]
MyBGTiles:
	LOAD "My background tiles in VRAM", VRAM[$8500]
		vMyBGTiles:
		.Filled1:
			REPT 8
				dw `11111111
			ENDR
		.Filled2:
			REPT 8
				dw `22222222
			ENDR
		.Funky1:
			REPT 3
				dw `10110111
				dw `11011112
			ENDR
			dw `11111111
			dw `12121212
		.Funky2:
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

SECTION "Variables in HRAM", HRAM
hMetaspriteX: db
hMetaspriteY: db
hMetaspriteVX: db
hMetaspriteVY: db
