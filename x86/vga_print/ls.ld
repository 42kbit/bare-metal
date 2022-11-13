OUTPUT_FORMAT("binary")
ENTRY(_start)
SECTIONS
{
	.text 0x7c00 : AT(0x7c00) {
		*(.mbr)
		FILL(0x0);
		. = 0x1fe;
		BYTE(0x55);
		BYTE(0xaa);
	}
}
