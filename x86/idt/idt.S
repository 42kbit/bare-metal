.code16

.section ".mbr"

/* Task:
load disk, load gdt, jump to proteced mode, 
then load idt and do funny
*/

.globl _start
_start:
	xorw %ax, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss	
	movw $0x7c00, %ax
	movw %ax, %bp
	movw %ax, %sp

.extern __stage2_nsectors
	/* reading disk */
	xorw %bx, %bx
	movw %bx, %es
	movw $0x8000, %bx
	movw $0x0200, %ax /* read %al sectors */
	/* may be buggy */
	movb $__stage2_nsectors, %al
	movw $0x0002, %cx
	movb $0x00, %dh
	int $0x13

	cli

	lgdt gdt_desc
	movl %cr0, %eax
	orl $1, %eax
	movl %eax, %cr0

	movw $GDT_DATA, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es

	ljmpl $GDT_CODE, $prot_entry

gdt_start:
null_d:
	.long 0x0
	.long 0x0
kcode_d:
	.word 0xffff
	.word 0x0000
	.byte 0x00
	.byte 0b10011010/* access byte */ 
	.byte 0b11001111/* flags, limit*/
	.byte 0x00
kdata_d:
	.word 0xffff
	.word 0x0000
	.byte 0x00
	.byte 0b10010010/* access byte */ 
	.byte 0b11001111/* flags, limit*/
	.byte 0x00
gdt_end:
gdt_desc:
	.word gdt_end - gdt_start - 1
	.long gdt_start

GDT_CODE=kcode_d-gdt_start
GDT_DATA=kdata_d-gdt_start

.section ".stage2", "ax"
.code32
.globl prot_entry

/*
.extern __end_align_4k
idt_ptr = __end_align_4k
idt_tbl = idt_ptr + 6

prot_entry:
	movw $(1*8-1), idt_ptr
	movl $idt_tbl, %eax
	movl $idt_ptr, %ebx
	movl %eax, 2(%ebx)

	movl $intr0_handler, %eax
	andl $0x0000ffff, %eax
	movl $GDT_CODE, %ebx
	shll $16, %ebx
	orl  %ebx, %eax
	movl %eax, idt_tbl

	movl $intr0_handler, %eax
	movb $0, %al
	movb $0b10001110, %ah
	movl $idt_tbl, %ebx
	movl %eax, 4(%ebx)
*/
idt_ptr:
.word idt_tbl_end - idt_tbl
.long idt_tbl
idt_tbl:
/* offset lower */
.word 0x0
.word GDT_CODE
/* reserved */
.byte 0x0
/*
0b1110 - intr gate,
7th bit - present
*/
.byte 0b10001110
/* offset high */
.word 0x0
idt_tbl_end:

prot_entry:
	movl $intr0_handler, %eax
	movl $idt_tbl, %ebx

	movw %ax, (%ebx)
	shll $16, %eax
	movw %ax, 6(%ebx)

	lidt idt_ptr

	sti
	movl $0, %ecx
	div %ecx
_die:
	hlt
	jmp _die

intr0_handler:
	movb $'b', 0xb8000
	iret
