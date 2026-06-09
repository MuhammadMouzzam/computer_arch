.option norvc
.text
.globl _start

_start:
    addi x1, x0, 0        # base address of arr
    addi x2, x0, 4        # n = 4
    addi x3, x0, 1        # i = 1

for_loop:
    slt  x8, x3, x2       # i < n
    beq  x8, x0, done

    slli x6, x3, 2        # offset = i * 4
    add  x6, x1, x6       # address of arr[i]
    lw   x5, 0(x6)        # key = arr[i]

    addi x4, x3, -1       # j = i - 1

while_loop:
    slt  x8, x4, x0       # j < 0
    bne  x8, x0, insert_key

    slli x6, x4, 2        # offset = j * 4
    add  x6, x1, x6       # address of arr[j]
    lw   x7, 0(x6)        # arr[j]

    slt  x8, x5, x7       # key < arr[j]
    beq  x8, x0, insert_key

    addi x10, x4, 1       # j + 1
    slli x11, x10, 2      # offset = (j + 1) * 4
    add  x11, x1, x11     # address of arr[j + 1]
    sw   x7, 0(x11)       # arr[j + 1] = arr[j]

    addi x4, x4, -1       # j--
    jal  x0, while_loop

insert_key:
    addi x10, x4, 1       # j + 1
    slli x11, x10, 2      # offset = (j + 1) * 4
    add  x11, x1, x11     # address of arr[j + 1]
    sw   x5, 0(x11)       # arr[j + 1] = key

    addi x3, x3, 1        # i++
    jal  x0, for_loop

done:
    jal  x0, done