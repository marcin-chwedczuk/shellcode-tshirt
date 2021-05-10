

all: wrapper shellcode

wrapper: wrapper.c shellcode.h
	gcc -o wrapper -z execstack wrapper.c

shellcode.h: shellcode.bytes
	xxd -i shellcode.bytes shellcode.h	

shellcode.bytes: shellcode
	objcopy -I elf32-little -O binary --only-section=.shcode shellcode shellcode.bytes
	chmod -x shellcode.bytes

shellcode: shellcode.o
	ld -o shellcode shellcode.o

shellcode.o: shellcode.asm
	nasm -f elf32 -o shellcode.o shellcode.asm

clean:
	rm -f shellcode shellcode.{o,h} shellcode.bytes
	rm -f wrapper
