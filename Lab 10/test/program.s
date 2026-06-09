.option norvc
.text
.globl _start

_start:

# R-type instruction codes
    add  x3,  x1, x2
    sub  x4,  x1, x2
    sll  x5,  x1, x2
    slt  x6,  x1, x2
    sltu x7,  x1, x2
    xor  x8,  x1, x2
    srl  x9,  x1, x2
    sra  x10, x1, x2
    or   x11, x1, x2
    and  x12, x1, x2

# I-type arithmetic instruction codes
    addi  x13, x1, 10
    slli  x14, x1, 3
    slti  x15, x1, 10
    sltiu x16, x1, 10
    xori  x17, x1, 15
    srli  x18, x1, 2
    srai  x19, x1, 2
    ori   x20, x1, 15
    andi  x21, x1, 15

# Load instruction codes
    lb  x22, 1(x1)
    lh  x23, 2(x1)
    lw  x24, 4(x1)
    lbu x25, 1(x1)
    lhu x26, 2(x1)

# Store instruction codes
    sb x2, 8(x1)
    sh x2, 10(x1)
    sw x2, 12(x1)

# U-type instruction code
    lui x27, 0x12345

# BEQ with +8 target
beq_x1_x2_plus8:
    beq  x1, x2, beq_x1_x2_target
    addi x31, x0, 1
beq_x1_x2_target:
    addi x30, x0, 2

# BNE with +8 target
bne_x1_x2_plus8:
    bne  x1, x2, bne_x1_x2_target
    addi x31, x0, 1
bne_x1_x2_target:
    addi x30, x0, 2

# JAL with +8 target
jal_x10_plus8:
    jal  x10, jal_x10_target
    addi x31, x0, 1
jal_x10_target:
    addi x30, x0, 2

# ALU-to-ALU RAW hazard on rs1
hazard_alu_rs1:
    add x3, x1, x2
    add x4, x3, x2

# ALU-to-ALU RAW hazard on rs2
hazard_alu_rs2:
    add x3, x1, x2
    sub x4, x2, x3

# ALU-to-ALU RAW hazard on both source operands
hazard_alu_both:
    add x3, x1, x2
    add x4, x3, x3

# ALU result used as load base address
hazard_alu_to_load_base:
    add x5, x1, x2
    lw  x6, 0(x5)

# Load-use RAW hazard
hazard_load_use:
    lw  x6, 0(x1)
    add x7, x6, x2

# Load result used as store data
hazard_load_to_store_data:
    lw x6, 0(x1)
    sw x6, 4(x1)

# ALU result used as store data
hazard_alu_to_store_data:
    add x6, x1, x2
    sw  x6, 8(x0)

# Branch comparison uses forwarded ALU result
hazard_branch_forward_taken:
    add x3, x1, x2
    beq x3, x4, hazard_branch_target
    addi x31, x0, 1
hazard_branch_target:
    addi x30, x0, 2

# Branch not taken case
hazard_branch_not_taken:
    bne  x3, x4, hazard_bne_target
    addi x31, x0, 1
hazard_bne_target:
    addi x30, x0, 2

# JAL control hazard
hazard_jal_flush:
    jal  x10, hazard_jal_target
    addi x31, x0, 1
hazard_jal_target:
    addi x30, x0, 2

# x0 destination should not cause forwarding
hazard_x0_no_forward:
    add x0, x1, x2
    add x3, x0, x2

# NOP instruction
    nop