; Interrupt handlers
SECTION "VBlank handler", ROM0[$40]
	jp DoTheScroll

SECTION "STAT handler", ROM0[$48]
	jp ScanlineMadness


DEF title  EQUS "AZULEJOS2" ; max 11 chars
DEF gameid EQUS "AZL2"     ; max  4 chars

SECTION "Header", ROM0[$100]
	di
	jp $150
	ds $134 - @, 0
	db "{title}"
	ds $13f - @, 0
	db "{gameid}"
	ds $150 - @, 0


;DEF rLY = $FF00+$44

SECTION "Entry point", ROM0[$150]
WaitForVBlank:
	ldh A, [$FF00+$44] ; LY
	cp 144
	jr nz, WaitForVBlank

TurnOffLCD:
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
	ld BC, $2020  ; B = 32 rows, C = 32 columns
	ld HL, $9800  ; The start of the 1st tilemap
	ld A, $50
.loop_C:
	xor 1         ; Toggle A between $50 and $51
	ld [HL+], A   ; Wrote  $50 or $51 to the tile index pointed by HL and inc HL
	; Alright
	; Now starts the 32x32 looping logic
	dec C
	jr nz, .loop_C
	; At every 32th iteration:
	dec B
	; Did we finish all rows?
	jr z, .end
	; Iterate through the next row
	ld C, $20
	xor 1  ; Toggle again at end of row for a checkered pattern instead of vertical stripes
	jr .loop_C
.end

SetupDisplayRegisters:
	ld A, %11_10_01_00 :: ldh [$FF47], A
	ld A, 64           :: ldh [$FF45], A
	ld A, %01000000    :: ldh [$FF41], A  ; Select LYC for STAT interrupt
	ld A, %00000011    :: ldh [$FFFF], A  ; enable VBlank and STAT interrupts

	; Turn LCD back on and enable interrupts
	ld HL, $FF40 :: set 7, [HL]
	ei

Done:
	halt
	jp Done



DoTheScroll:
	; Move window 5 pixels to the right
	ldh A, [$FF42] :: inc A :: ldh [$FF42], A  ; SCY
	ldh A, [$FF43] :: dec A :: ldh [$FF43], A  ; SCX
	reti


ScanlineMadness:
	; ld A, %11_00_00_00
	; ldh [$FF47], A
	reti



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
		.end:
	ENDL
.end:
ENDSECTION