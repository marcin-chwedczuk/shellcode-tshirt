
#include <unistd.h>


int main(int argc, char** argv) {

	char* args[] = { "/bin/sh", NULL };
	execve(args[0], &args[0], &args[1]);
}
