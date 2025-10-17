/* link.ld */
ENTRY(_start)

MEMORY
{
    IMEM  (rx)  : ORIGIN = 0x00000000, LENGTH = 0x00010000   /* 64 KB IMEM area */
    DMEM  (rwx) : ORIGIN = 0x00020000, LENGTH = 0x00010000   /* 64 KB DMEM area */
}

SECTIONS
{
  . = ORIGIN(IMEM);
  .text : { *(.text*) } > IMEM

  /* rodata can go to IMEM */
  .rodata : { *(.rodata*) } > IMEM

  /* data/bss in DMEM */
  . = ORIGIN(DMEM);
  .data : { *(.data*) } > DMEM
  .bss  : { *(.bss*) } > DMEM
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM); /* define stack top at end of DMEM */
}

