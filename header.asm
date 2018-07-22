.memorymap
  slotsize $8000
  defaultslot 0
  slot 0 $8000
.endme

.rombanksize $8000
.rombanks 8

.snesheader
  id "SNES"
  name "SNES Dev             "
      ; 123456789012345678901
  fastrom
  lorom
  cartridgetype $00
  romsize $08
  sramsize $00
  country $01
  licenseecode $00
  version $00
.endsnes

.snesnativevector
  cop null_handler
  brk null_handler
  abort null_handler
  nmi vblank
  irq null_handler
.endnativevector

.snesemuvector
  cop null_handler
  abort null_handler
  nmi vblank
  reset start
  irqbrk null_handler
.endemuvector

.emptyfill $00
