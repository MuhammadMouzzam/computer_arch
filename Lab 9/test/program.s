.option norvc
.text
.globl _start

_start:
    add  x3, x1, x2
    nop
    nop
    nop

    sub  x4, x1, x2
    nop
    nop
    nop

    addi x5, x1, 10
    nop
    nop
    nop

    andi x6, x1, 15
    nop
    nop
    nop

    lw   x7, 0(x1)
    nop
    nop
    nop

    sw   x2, 0(x1)
    nop
    nop
    nop

    lui  x8, 0x12345
    nop
    nop
    nop