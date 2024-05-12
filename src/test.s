DEF rJOYP       EQU $FF00
DEF rLCDC       EQU $FF40
DEF rSTAT       EQU $FF41
DEF rDMA        EQU $FF46
DEF rBGP        EQU $FF47
DEF rOBP0       EQU $FF48
DEF rOBP1       EQU $FF49
DEF rIE         EQU $FFFF

DEF name      EQUS "SGB Upload"

SECTION "vblank",ROM0[$40]
	reti

SECTION "boot",ROM0[$100]
	jp _start

SECTION "header",ROM0[$134]
	db "{name}"
REPT ($f - strlen("{name}"))
	db 0
ENDR
	db $80 ; CGB support
	db $00, $00 ; Licensee code
	db $03 ; SGB flag
	db $00, $00, $00 ; MBC, ROM size, RAM size
	db $01 ; Destination code
	db $33 ; Use new licensee code
	db $00 ; Version

SECTION "main",ROM0[$150]
_start:
	; Turn on SGB masking
	ld hl, mask_en_3
	call sgb_cmd

	ld a, $E4
	ldio [rBGP], a
	ld a, $E4
	ldio [rOBP0], a
	ld a, $00
	ldio [rOBP1], a

	; Set up vblank IRQ, then turn off screen
	di
	ld a, $01
	ldio [rIE], a
	ld a, $80
	ldio [rLCDC], a
	ei
	halt
	nop
	di
	xor a, a
	ldio [rLCDC], a
	ei

	; Set up OBJs
	ld bc, oam_dma
	ld hl, oam_code
	ld d, oam_dma.end - oam_dma
.copy_loop
	ld a, [bc]
	inc bc
	ld [hl+], a
	dec d
	jr nz, .copy_loop
	call oam_code

	; Create char data
	ld hl, $8000
	ld bc, $00FF
	call store_tile

	; Clear Nintendo logo
	ld hl, $9900
	ld a, $01
	ld b, $40
.clear_loop
	ld [hl+], a
	dec b
	jr nz, .clear_loop

	; Turn screen back on
	ld a, $91
	ldio [rLCDC], a
	; Transfer char data
	ld hl, chr_trn
	call sgb_cmd
	halt
	halt
	halt
	halt
	halt
	; Turn screen back off
	xor a, a
	ldio [rLCDC], a

	; Create tile data
	ld hl, $8000
	; Tilemap
	ld bc, $1000
	call store_tile
	; BG palette data (red)
	ld bc, $001F
	call store_tile
	; BG palette data (green)
	ld bc, $03E0
	call store_tile
	; BG palette data mask (for OBJ)
	ld bc, $0C10
	call store_tile

	; Map in palette data
	ld hl, $98C0
	ld a, $01
	ld b, $80
.fill_loop
	ld [hl+], a
	dec b
	jr nz, .fill_loop

	; Turn screen back on
	ld a, $93
	ldio [rLCDC], a
	; Transfer map data
	ld hl, pct_trn
	call sgb_cmd
	halt
	halt
	halt
	halt
	halt

	ld hl, mask_en_0
	call sgb_cmd

	; Stall forever
.forever
	halt
	nop
	jr .forever

store_tile:
REPT 8
	ld a, c
	ld [hl+], a
	ld a, b
	ld [hl+], a
ENDR
	ret

sgb_byte:
REPT 7
	ld a, $01
	and a, b
	inc a
	cpl
	swap a
	ldio [rJOYP], a
	ld a, $FF
	nop
	nop
	ldio [rJOYP], a
	srl b
	nop
	nop
	nop
	nop
ENDR
	ld a, $01
	and a, b
	inc a
	cpl
	swap a
	ldio [rJOYP], a
	ld a, $FF
	nop
	nop
	ldio [rJOYP], a
	nop
	nop
	nop
	nop
	ret

sgb_cmd:
	ld a, $CF
	ldio [rJOYP], a
	ld a, $FF
	nop
	nop
	ldio [rJOYP], a
	nop
	nop
	nop
	nop
	nop
	nop
REPT 16
	ld a, [hl+]
	ld b, a
	call sgb_byte
ENDR
	ld a, $EF
	ldio [rJOYP], a
	ld a, $FF
	nop
	nop
	ldio [rJOYP], a
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret

SECTION "oam",ROM0[$400]
oam_start:
	db $40, $48, $03, $10
	db $40, $50, $03, $10
	db $40, $58, $03, $10
	db $40, $60, $03, $10
	db $40, $48, $02, $00
	db $40, $50, $02, $00
	db $40, $58, $02, $00
	db $40, $60, $02, $00
	ds $80

SECTION "data",ROM0[$4A0]
oam_dma:
	ld a, oam_start / $100
	ld [rDMA], a
	ld a, $28
.loop:
	dec a
	jr nz, .loop
	ret
.end:

chr_trn:
	db ($13 << 3) + 1
	ds $0f

pct_trn:
	db ($14 << 3) + 1
	ds $0f

mask_en_0:
	db ($17 << 3) + 1
	db $00
	ds $0e

mask_en_3:
	db ($17 << 3) + 1
	db $03
	ds $0e


SECTION "oam_code",HRAM[$FF80]
oam_code:
	ds oam_dma.end - oam_dma
