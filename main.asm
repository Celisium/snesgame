.include "header.asm"

.bank 0 slot 0
.org 0
.section "main_code"

.enum $0000
scratch ds 16
first_column_draw_buffer ds 16
scroll_x dw
scroll_y dw
.ende

.base $80

null_handler:
  rti

vblank:
  jml + ; Required for FastROM.
+

  rti

start:

.include "init.asm"

  ; Set up FastROM.
  jml +
+
  phk
  plb
  lda #%00000001
  sta $420D

  ; Load palette.
  stz $2121
  stz $4300
  lda #$22
  sta $4301
  lda #<palette
  sta $4302
  lda #>palette
  sta $4303
  lda #:palette
  sta $4304
  stz $4305 ; Low byte of 512 is zero.
  lda #%00000010 ; High byte of 512.
  sta $4306
  lda #%00000001
  sta $420B

  ; Mode 1, 16x16 BG1/2, 8x8 BG3, default priority.
  lda #%00110001
  sta $2105

  ; Set VRAM base registers.
  lda #%01100000
  sta $2107
  lda #%01100100
  sta $2108
  lda #%01101000
  sta $2109
  stz $210A

  lda #%00100000
  sta $210B
  lda #%01100100
  sta $210C

  lda #%10000000
  sta $2115
  stz $2116  
  stz $2117

  lda #%00000001
  sta $4300
  lda #$18
  sta $4301
  lda #<tiles
  sta $4302
  lda #>tiles
  sta $4303
  lda #:tiles
  sta $4304
  stz $4305 ; Low byte of 8192 is zero.
  lda #$20 ; High byte of 8192.
  sta $4306
  lda #%00000001
  sta $420B

  stz scroll_x
  stz scroll_x + 1
  stz scroll_y
  stz scroll_y + 1

  jsr clear_level_data

  lda #<level_data
  sta scratch + 0
  lda #>level_data
  sta scratch + 1
  jsr load_level_data

  ldx #0
  jsr draw_screen_right_edge

  lda #%00000001
  sta $212C

  ; Turn on screen.
  lda #$0F
  sta $2100

forever:
  jmp forever

load_level_data:

  stz scratch + 15 

  sep #%00100000

  ldy #$0000
  ldx #$0000

  lda (scratch + 0),Y
  sta scratch + 2
  iny
  lda (scratch + 0),Y
  sta scratch + 3
  iny
  lda (scratch + 0),Y
  sta scratch + 4
  iny
  lda (scratch + 0),Y
  sta scratch + 5
  iny
  lda (scratch + 0),Y
  sta scratch + 6
  iny
  lda (scratch + 0),Y
  sta scratch + 7
  iny
  lda (scratch + 0),Y
  sta scratch + 8
  iny
  lda (scratch + 0),Y
  sta scratch + 9

  rep #%00110000
  lda scratch + 4
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  clc
  adc scratch + 6
  sta scratch + 10
  sep #%00100000

  lda scratch + 8
  sta scratch + 12
  lda scratch + 9
  sta scratch + 13

-
  lda scratch + 8
  sta scratch + 12

  lda scratch + 10
  sec
  sbc #16
  sta scratch + 10
  lda scratch + 11
  sbc #0
  sta scratch + 11

  lda scratch + 10
  clc
  adc #0
  sta scratch + 10
  lda scratch + 11
  adc #1
  sta scratch + 11

--
  lda scratch + 2
  ldx scratch + 10
  sta $7F0000,X

  lda scratch + 10
  clc
  adc #1
  sta scratch + 10
  lda scratch + 11
  adc #0
  sta scratch + 11

  inc scratch + 15

  dec scratch + 12
  bne --

  dec scratch + 13
  bne -

  sep #%00110000

  rts

clear_level_data:
  rep #%00110000
  lda #$0000
  ldx.w #$FFFE
-
  sta $7F0000,X
  dex
  dex
  bne -

  sep #%00110000
  rts

draw_screen_right_edge:

  rep #%00110000

  ; Get the tile coordinates of the top-right corner of the screen.
  lda scroll_x
  lsr
  lsr
  lsr
  lsr
  clc
  adc #16
  sta scratch + 0
  lda scroll_y
  lsr
  lsr
  lsr
  lsr
  sta scratch + 2

  ; Get the base address within the world buffer.
  lda scratch + 2
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  clc
  adc scratch + 0
  sta scratch + 4

  sep #%00110000

  ; Set the data bank.
  phb
  lda #$7F
  pha
  plb

  ; Load from the world buffer to the first column buffer.
  ldx #0
-
  lda.l (scratch + 4)
  sta.l first_column_draw_buffer,X
  lda.l scratch + 4
  clc
  adc #%00000000
  sta.l scratch + 4
  lda.l scratch + 5
  adc #%00000001
  sta.l scratch + 5
  inx
  cpx #16
  bne -

  plb

  ; Calculate the address to store into.
  rep #%00110000
  lda scroll_y
  and #$00FF
  asl
  sta scratch + 6

  lda scroll_x
  and #$00FF
  lsr
  lsr
  lsr
  lsr
  clc
  adc #16
  sta scratch + 8

  lda scratch + 6
  clc
  adc scratch + 8
  clc
  adc #$6000
  sta scratch + 10

  sep #%00110000

  ; Begin transferring data to VRAM.
  lda #%10000001
  sta $2115
  lda scratch + 10
  sta $2116
  lda scratch + 11
  sta $2117

  ldx #0
-
  ldy first_column_draw_buffer,X
  lda tile_data_tiles,Y
  sta $2118
  lda tile_data_palettes,Y
  sta $2119
  inx
  cpx #16
  bne -

  rts

tile_data_tiles:
  .db $00
  .db $03
  .db $02
  .db $04
  .db $06
  .db $07
.repeat 256
  .db $01
.endr
tile_data_palettes:
.repeat 256
  .db %00000000
.endr

.seed 1234
palette:
  .dbrnd 512, 0, 255

tiles:
  .incbin "test.chr"

level_data:
  .db $01 $00
  .dw $0010 $0000
  .db $2 $10

  .db $00 $00
  .dw $0000 $0000
  .db $00 $00

.ends
