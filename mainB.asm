; example 3b SNES code

.p816
.smart

.include "defines.asm"
.include "macros.asm"
.include "init.asm"
.include "unrle.asm"




.segment "CODE"

; enters here in forced blank
main:
.a16 ; just a standardized setting from init code
.i16
	phk
	plb
	

	
; DMA from Palette_Copy to CGRAM
	A8
	stz $2121 ; $2121 cg address = zero
	
	stz $4300 ; transfer mode 0 = 1 register write once
	lda #$22  ; $2122
	sta $4301 ; destination, pal data
	ldx #.loword(BG_Palette)
	stx $4302 ; source
	lda #^BG_Palette
	sta $4304 ; bank
	ldx #32
	stx $4305 ; length
	lda #1
	sta $420b ; start dma, channel 0
	
	
; DMA from Tiles to VRAM	
	lda #V_INC_1
	sta vram_inc ; set the increment mode +1
	ldx #$0000
	stx vram_addr ; set an address in the vram of $0000
	lda #1
	sta $4300 ; transfer mode, 2 registers 1 write
			  ; $2118 and $2119 are a pair Low/High
	lda #$18  ; $2118
	sta $4301 ; destination, vram data

; decompress first
	AXY16
	lda #.loword(Tiles)
	ldx #^Tiles
	jsl unrle ; unpacks to 7f0000 UNPACK_ADR
	; returns y = length
	; ax = unpack address (x is bank)
	sta $4302 ; source
	txa
	A8
	sta $4304 ; bank
	sty $4305 ; length
	lda #1
	sta $420b ; start dma, channel 0
	
	
	
; DMA from Tilemap to VRAM	
	ldx #$6000
	stx vram_addr ; set an address in the vram of $6000
	
; decompress first
	AXY16
	lda #.loword(Tilemap)
	ldx #^Tilemap
	jsl unrle ; unpacks to 7f0000 UNPACK_ADR
	; returns y = length
	; ax = unpack address (x is bank)
	sta $4302 ; source
	txa
	A8
	sta $4304 ; bank
	sty $4305 ; length
	lda #1
	sta $420b ; start dma, channel 0
	
	
; a is still 8 bit.
	lda #1 ; mode 1, tilesize 8x8 all
	sta bg_size_mode
	
; 210b = tilesets for bg 1 and bg 2
; (210c for bg 3 and bg 4)
; steps of $1000 -321-321... bg2 bg1
	stz $210b ; both at VRAM address $0000
	
	; 2107 map address bg 1, steps of $400, but -54321yx
	; y/x = map size... 0,0 = 32x32 tiles
	; $6000 / $100 = $60
	lda #$60 ; address $6000
	sta $2107

	lda #BG1_ON	; only bg 1 is active
	sta main_screen ; $212c
	
	lda #FULL_BRIGHT ; $0f = turn the screen on (end forced blank)
	sta fb_bright ; $2100


InfiniteLoop:	
	jmp InfiniteLoop
	
	
	
.include "header.asm"	


.segment "RODATA1"

BG_Palette:
; 32 bytes
.incbin "ImageConverter/moon.pal"

Tiles:
; 4bpp tileset compressed
.incbin "RLE/tiles.rle"

Tilemap:
; tilemap compressed
.incbin "RLE/map.rle"

