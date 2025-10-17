    .section .text
    .globl _start
_start:
    /* set up stack pointer — choose an address in DMEM region top */
    la sp, _stack_top    /* uses linker symbol */
    /* call main */
    call main
    /* if main returns, hang */
1:  j 1b

