
; For some reason I cannot make .text section both exec and writable.
; So instead of fighting with ld and nasm I decided to use my own section '.shcode'
; Linux allows _start symbol to be contained in any executable section.
; So this program runs without problems on 32-bit Linux.

section .shcode progbits alloc exec write
global _start 

_start:
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
	db  '/bin/sh' ; esi will point here

