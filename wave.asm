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

EntryPoint:
	ld A, 8 :: ld [wNextLYC], A
	xor A   :: ld [wCurBGPIdx],  A

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
.loop:
	xor 1         ; Toggle A between $50 and $51
	ld [HL+], A   ; Wrote  $50 or $51 to the tile index pointed by HL and inc HL
	bit 2, H      ; Becomes 1 when HL reaches $9C00
	jr z, .loop

SetupDisplayRegisters:
	ld A, %11_10_01_00 :: ldh [$FF47], A  ; BGP
	ld A, [wNextLYC]   :: ldh [$FF45], A  ; LYC
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
	; HL = &myBGPs[wCurBGPIdx] = myBGPs + wCurBGPIdx
	xor A
	ld HL, wCurBGPIdx
	ld D, A
	ld E, [HL]
	ld HL, myBPGs
	add HL, DE

	; BGP = *HL
	ld A, [HL]
	ldh [$FF47], A

	; LYC += 8
	ld A, [wNextLYC]
	add 8
	ldh [$FF45], A
	ld [wNextLYC], A
	ld A, %01000000    :: ldh [$FF41], A  ; Select LYC for STAT interrupt


	; wCurBGPIdx ^= 1
	ld A, [wCurBGPIdx]
	xor 1
	ld [wCurBGPIdx], A

	; return
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


SECTION "Alternating palettes", ROM0[$600], ALIGN[1]
myBPGs: db %11_10_01_00, %11_01_10_00


SECTION "Variables in WRAM", WRAM0
wNextLYC: db
wCurBGPIdx: db