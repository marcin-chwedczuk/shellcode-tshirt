

My company sent me recently this wonderful t-shirt:

![t-shirt picture](imgs/tshirt.jpeg)

The text printed on it looks very much like the output of `objdump -d shellcode.o` command.

Let's figure out if the shellcode actually works.

If you had a chance to write your own shellcode, you will immediately recognize this `jmp`, `call`, `pop` pattern.
In pure form it looks like this (NASM syntax):
```asm
        jmp short _end
_run:
        pop esi
        ; now esi register contains address of data label

        ; actual shellcode instructions go here
_end:
        call _run 

data:
        db 'some data'
```
When we use shellcode on a real system, we have no idea at which memory address our shellcode will be loaded. Sometimes this information can be very useful e.g. when our shellcode contains not only code but also data.
While `jmp`s and `call`s can operate on relative addresses, thus allowing us to write position independent code (PIC), the data access instructions (`mov`s) need absolute addresses. 

NOTE: The last sentence is no longer true on x86_64 architecture, as it introduced a new addressing mode called "RIP relative addressing".

When we use `jmp` and `call` instructions in relative address mode, we are actually using offsets relative to the _next_ instruction following `jmp` or `call` opcode.
So a relative jump `jmp short 0` (again NASM syntax), will just jump to the next instruction and `jmp short -2` will create an infinite loop (assuming that the entire `jmp` instruction takes two bytes).

`call offset` instruction is more interesting, as it will not only jump to the offset, but also will push the address of the following instruction on the stack (the so called return address).

Now we can understand how `jmp`, `call`, `pop` pattern works.
First we need to position `call` instruction just before the data, of which we want to get address. Then we do a relative jump to the `call`. The `call` will put the address of the next instruction (in this case our data) on the stack and will again do a relative jump to the specified offset. Now we have the address of our data on the stack, so we may just `pop` it into a register of our choice :tada:

When we take a look at the t-shirt again, we may notice that the actual offsets printed there are wrong. `jmp 0x2b` should be in fact `jmp 0x2a` because the address of `call` instruction is `0x2f = 0x05 + 0x2a`. The `call` instruction on the other hand should jump to the `pop esi` instruction, so the offset should be `0x2f (call addr) + 0x05 (length of call instruction) + offset = 0x05`, or `-0x2f` (using 2's complement this value can be represented as `0xffffffd1`).

Right after `pop esi` we have sequence of three move instructions:
```asm
	mov    dword ptr [esi+0x8], esi
	mov    byte  ptr [esi+0x7], 0x0
	mov    dword ptr [esi+0xc], 0x0
```
We know now that `esi` points to the area after our last shellcode instruction.
We may illustrate this memory area as:
```
ESI+0: ??|??|??|?? 
ESI+4: ??|??|??|??
ESI+8: ??|??|??|??
ESI+c: ??|??|??|??
```
After executing all these move instructions (in intel syntax that we have here, it is always `mov dest, src`) our memory area will look like this:
```
ESI+0: ??|??|??|?? 
ESI+4: ??|??|??|00
ESI+8: [value of esi register]
ESI+c: 00|00|00|00
```

Now this is interesting. Looks like we have a seven character string terminated by zero, then a pointer to that string and a `NULL` value.

:thinking: Seven character string, seven character string...  when it is about shellcodes it must be `/bin/sh` :D So it looks like the shellcode on the t-shirt is truncated, the last two instruction should look like this:
```asm
	call 0xffffffd1 ; must be a relative call
	db  '/bin/sh'
```
And our mysterious memory area should be:
```
ESI+0: /|b|i|n 
ESI+4: /|s|h|00
ESI+8: [value of esi register]
ESI+c: 00|00|00|00
```

Now that we know what the missing bytes are, we may expect that our shellcode is calling one of the `execve` functions.
In C `execve` is declared in `unistd.h` as:
```c
int execve(const char *path, char *const argv[], char *const envp[]);
```
It takes three arguments that should be know to every C programmer out there.
Both `argv` and `envp` arrays contain pointers to strings and must be terminated
by an entry containing `NULL`. Here is how we may use `execve` in C:
```c
int main(int argc, char** argv) {
	char* args[] = { "/bin/sh", NULL };
	char* env[] = { NULL };
	execve(args[0], args, env);
}
```
Actually when `env` is empty we may compress this code a bit (by reusing `NULL` already present in `args` array):
```c
int main(int argc, char** argv) {
	char* args[] = { "/bin/sh", NULL };
	execve(args[0], &args[0], &args[1]);
}
```
Notice that `args` array looks similar to our memory area starting at `ESI+8`.

When we return to the t-shirt code and check the next instructions we see:
```asm
	mov    eax, 0xb ; execve(filename, argv, envp)
	mov    ebx, esi 
	lea    ecx, [esi+0x8] 
	lea    edx, [esi+0xc]
	int    0x80
```
The `int 0x80` instruction is the standard way to call the Linux kernel from 32-bit code (64-bit code nowadays usually uses `syscall` instruction).
When we call a system function, we pass the function arguments in
`ebx`, `ecx`, `edx`, `esi`, `edi` and `ebp` registers in exactly that order.
`eax` register is used to select the function itself. We may see the list of all available functions [here](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#x86-32_bit).

For example to call `exit(0)`, first we need to check the value that system assigned to `exit` function (`0x01`) and put it in `eax` register.
`exit(0)` takes one argument. We must put that argument value in `ebx` register
(subsequent arguments would go in `ecx`, then `edx` and so on).
Finally we may call the kernel using `int 0x80` software interrupt:
```asm
        ; C equivalent:
        ; exit(0);

        mov    eax, 0x1
	mov    ebx, 0x0
	int    0x80
```

`execve` function is assigned to number `0x0b`. And when we look at the t-shirt again, there, after a block of `mov`s we can see that exactly this function is
called:
```asm
	mov    eax, 0xb ; execve(filename, argv, envp)
	mov    ebx, esi 
	lea    ecx, [esi+0x8] 
	lea    edx, [esi+0xc]
	int    0x80
```
`lea` instruction is used to load the address of the operand to the specified register.
But here since we use indirect memory addressing, `lea ecx, [esi+0x8]`
is equivalent to `ecx = esi + 0x08` in C.

After all these `mov`s and `lea`s we have the address of `/bin/sh` string in `ebx`, the address of `args` array (pointer to `/bin/sh` followed by `NULL`)
in `ecx` and finally address of `NULL` in `edx`.
In other words our code is equivalent to the C code that we saw earlier:
```c
int main(int argc, char** argv) {
	char* args[] = { "/bin/sh", NULL };
	execve(args[0], &args[0], &args[1]);
}
```

What follows call to `execve`, is a call to `exit(0)`. This is a standard technique used in shellcode to just exit the program without crashing it. This way we will leave no traces of our code (think no coredumps).

All in all the code on my t-shirt should look like this:
```asm
	jmp   short _sh_last
 
_sh_start:
	pop    esi

	mov    dword [esi+0x8], esi
	mov    byte  [esi+0x7], 0x0
	mov    dword [esi+0xc], 0x0

	mov    eax, 0xb ; execve(filename, argv, envp)
	mov    ebx, esi 
	lea    ecx, [esi+0x8] 
	lea    edx, [esi+0xc]
	int    0x80

	mov    eax, 0x1 ; exit(0)
	mov    ebx, 0x0
	int    0x80

_sh_last:
	call   _sh_start
	db  '/bin/sh'
```

Now the moral of this story: always put a _working_ shellcode on t-shirts to avoid further embarrassment by posts like this one ;)

Bonus: This repo contains a `Makefile` that will build the shellcode and also prepare a C header file containing the shellcode bytes. There is also a wrapper program that will demonstrate that the shellcode indeed works. The only thing that you need is a 32-bit Linux.

You can check if a Linux system is 32-bit using `uname -a` command:
```
uname -a
Linux 4.15.0-133-generic #137~16.04.1-Ubuntu SMP Fri Jan 15 02:55:05 UTC 2021 i686 i686 i686 GNU/Linux
```
If you see `i386` or `i686` then your system is 32-bit.

To compile the assembly code you will need `nasm`. You can install it using `apt-get`.

```
make clean
make all
./shellcode
./wrapper
```