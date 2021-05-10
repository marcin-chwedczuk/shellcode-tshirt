

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
When we use shellcode on a real system, we have no idea at which memory address our shellcode will be located. Sometimes this information can be very useful e.g. when our shellcode contains not only code but also data.
While `jmp`s and `call`s can operation on relative addresses, thus allowing us to write position independent code (PIC), the data access instructions (`mov`s) need absolute addresses. 

NOTE: The last sentence is no longer true on x86_64 architecture, as it introduced a new addressing mode called "RIP relative addressing".

When we use `jmp` and `call` instructions in relative address mode, we are actually using offsets relative to the _next_ instruction following `jmp` or `call` opcode.
So a relative jump `jmp short 0` (again NASM syntax), will just jump to the next instruction.

`call offset` instruction is more interesting as it will not only jump to the offset but also it will push the address of the instruction _following_ it on the stack (the so called return address).

Now we can understand how `jmp`, `call`, `pop` pattern works.
First we need to locate `call` instruction just before the data, of which we want to get the address. Then we do a relative jump to the `call`. The `call` will put the address of the next instruction (in this case our data) on the stack and will again do a relative jump to the specified offset. Now we have the address of our data on the stack, so we may just `pop` it into a register of our choice :tada:

