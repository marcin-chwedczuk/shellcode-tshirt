#include <stdio.h>
#include <string.h>

#include "shellcode.h"

int main(int argc, char** argv) {

	char buff[1024];
	memcpy(buff, shellcode_bytes, shellcode_bytes_len);

	void (*f)() = (void *)&buff[0];
	f();

	return 0;
}
