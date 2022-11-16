.code16

.section ".mbr"

/* Task:
load disk, load gdt, jump to proteced mode, 
then enable paging, that maps 0x0 (virtual addr) to 0x1000 (phys addr)
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
.extern kmain
.globl prot_entry
prot_entry:
	cld
	jmp kmain
