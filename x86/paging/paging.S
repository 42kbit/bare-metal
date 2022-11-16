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

.extern __end_align_4k

page_directory = __end_align_4k

page_table = __end_align_4k + 0x1000

.section ".stage2", "ax"
.code32
.globl prot_entry
/* protected mode loaded, now enable paging. */
prot_entry:

	/* memset(page_directory, 0, 4096) */
	cld
	movl $0x1000, %ecx
	movl $page_directory, %edi
	rep stosl

	/* memset(page_table, 0, 4096) */
	movl $0x1000, %ecx
	movl $page_table, %edi
	rep stosl

	/* setup page directory, that page_directory[0] points to page_table */
	movl $page_table, %eax
	andw $0xf000, %ax
	movb $0b00100111, %al
	movl %eax, page_directory

	/* init whole page_table */
	xorl %eax, %eax
	movl $page_table, %ebx
ptbl_init_lpbeg:
	/* if counter is 1024, all done, goto end */
	cmp $0x400, %eax
	je ptbl_init_lpend

	/* edx = (eax << 12)
		so that
		virt	phys
		0x0	0x0
		0x1	0x1000
		0x2	0x2000
	*/
	movl %eax, %edx
	shl $12, %edx

	/* present and writable page */
	movb $0b00000011, %dl
	/* clr bits 8-11 (avl bits) */
	andb $0xf0, %dh
	movl %edx, (%ebx)
	incl %eax
	addl $0x4, %ebx
	
	jmp ptbl_init_lpbeg
ptbl_init_lpend:

	/* set page_table[0], that virtual 0x0, maps to phys 0x1000 */

	movl page_table, %eax
	orl  $0x00001000, %eax
	movl %eax, page_table

	/* move page dir to cr3 */

	movl $page_directory, %eax
	movl %eax, %cr3
	
	/* enable paging, and do shit */

	movl %cr0, %eax
	orl $(1<<31), %eax
	movl %eax, %cr0

	movl $'a', %eax
	movb %al, 0x0 /* *(char)0x0 = 'a' */

	movl $'b', %eax
	movb %al, 0x1002 /* *(char)0x1002 = 'b' */
	
	movl %cr0, %eax
	andl $~(1<<31), %eax
	movl %eax, %cr0
	
	/* shit ended, now print result */

	movb 0x1000, %al
	movb %al, 0xb8000
	movb 0x1002, %al
	movb %al, 0xb8002

_die:
	hlt
	jmp _die
