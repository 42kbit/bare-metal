__attribute__((noreturn))
static inline void cpu_relax(void){
	while (1){
		asm volatile ("hlt;");
	}
}

typedef unsigned char 		u8;
typedef unsigned short int 	u16;
typedef unsigned int 		u32;

typedef char 		i8;
typedef short int 	i16;
typedef int 		i32;

typedef char sym;

extern sym __end_align_4k;

#define bit(x) (1<<x)
#define bitcut(val, where, by) ((val >> where) & bitmask(by))
#define bitmask(x) (bit(x) - 1)

static volatile u8 * const vga_text = (volatile u8*) 0xb8000;
#define get_hex_digit(x)\
	(x <= 9? (x+'0') : (x-10+'a'))
static inline void sget_hex(const void* _mem, u32 len, char* buf){
	const char* mem = _mem;
	for (i32 i = 0; i < len; i++){
		/* works for little endian */
		buf[i * 2 + 0] = get_hex_digit(bitcut(mem[i], 0, 4));
		buf[i * 2 + 1] = get_hex_digit(bitcut(mem[i], 4, 4));
	}
}

static inline void vga_write(const char* str, u32 len){
	for (i32 i = 0; i < len; i++){
		vga_text[(len-i-1)*2] = str[i];
	}
}

struct pg_dir_entry {
	u32
	   present 	: 1,
	   rd_wr	: 1,
	   usr_spw	: 1,
	   pwt		: 1,
	   cache_off	: 1,
	   acc		: 1,
	   avl0		: 1,
	   page_size	: 1,
	   avl		: 4,
	   adr		: 20;
} __attribute__((packed));

struct pg_tbl_entry {
	u32
	   present 	: 1,
	   rd_wr	: 1,
	   usr_spw	: 1,
	   pwt		: 1,
	   cache_off	: 1,
	   acc		: 1,
	   dirty	: 1,
	   pat		: 1,
	   global	: 1,
	   avl		: 3,
	   adr		: 20;
} __attribute__((packed));

#define PAGE_SIZE 4096

struct pg_dir_entry * __pg_dir_tbl = (struct pg_dir_entry*) &__end_align_4k;
struct pg_tbl_entry * __pg_tbl =
	(struct pg_tbl_entry*) ((char*)&__end_align_4k + PAGE_SIZE);

__attribute__((noreturn))
void kmain(void){
	for (i32 i = 0; i < 2048; i++){
		*((i32*)__pg_dir_tbl + i) = 0;
	}
	struct pg_dir_entry dir_entry = {
		.present 	= 1,
		.rd_wr 		= 1,
		.usr_spw 	= 1,
		.pwt 		= 0,
		.cache_off 	= 0,
		.acc		= 1,
		.avl0		= 0,
		.page_size	= 0,
		.avl		= 0,
		.adr		= ((u32)__pg_tbl & 0xfffff000) >> 12
	};
	__pg_dir_tbl[0] = dir_entry;
	struct pg_tbl_entry pg_entry = {
		.present 	= 1,
		.rd_wr 		= 1,
		.usr_spw 	= 0,
		.pwt 		= 0,
		.cache_off 	= 0,
		.acc		= 0,
		.dirty		= 0,
		.pat		= 0,
		.global		= 0,
		.avl		= 0,
		.adr		= 0
	};
	for (i32 i = 0; i < 1024; i++){
		__pg_tbl[i] = pg_entry;
		__pg_tbl[i].adr = i;
	}

/*
	int sec = __pg_tbl;
	char buf[8];
	sget_hex(&sec, 8, buf);
	vga_write(buf, 8);

	cpu_relax();
*/

	__pg_tbl[0].adr = 0x1;
	asm volatile ("movl __pg_dir_tbl, %%eax;"
		 	"movl %%eax, %%cr3;" ::: "eax");
	asm volatile ("movl %%cr0, %%eax;"
			"orl $(1<<31), %%eax;"
			"movl %%eax, %%cr0;" ::: "eax");
	*(volatile char*)0x0 = 'a';
	asm volatile ("movl %%cr0, %%eax;"
			"andl $~(1<<31), %%eax;"
			"movl %%eax, %%cr0;" ::: "eax");
	*(volatile char*)0xb8000 = *(volatile char*)0x1000;
	cpu_relax();
}
