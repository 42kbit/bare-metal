OUTPUT_FORMAT("binary")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	.mbr 0x7c00 : AT(0x0){
		*(.mbr)
		FILL(0x0);
		. = 0x1fe;
		BYTE(0x55);
		BYTE(0xaa);
	}
	__stage2_begin = . ;
	.stage2 ALIGN(4K) : AT(0x200) {
		KEEP(*(.stage2))
	}
	__stage2_nsectors = (. - __stage2_begin) / 512;

	. = 0x100000;
	
	.text	ALIGN(4K): { *(.text.*) }
	.bss	ALIGN(4K): { *(.bss.*) }
	.data	ALIGN(4K): { *(.data.*) }
	
	. = ALIGN(512);
	__end = .;
	__end_align_4k = ALIGN(4K);
}
