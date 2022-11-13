.code16

.section ".mbr"

.globl _start
_start:
	movw $msg_len, %cx

	xorw %ax, %ax
	movw %ax, %ds

	movw $0xb800, %ax
	movw %ax, %es

	movw $msg, %si

	cld
	rep movsb
	jmp .

msg:
.ascii "H\077e\077l\077l\077o\077,\077 \077w\077o\077r\077l\077d\077"
msg_len = . - msg
