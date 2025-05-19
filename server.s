.intel_syntax noprefix
.globl _start

.section .data
        http_response: .string "HTTP/1.0 200 OK\r\n\r\n"

.section .text

_start:
        # Prologue
        push    rbp
        mov     rbp, rsp
        sub     rsp, 0x20

        #open a socket
        mov edx, 0x0
        mov esi, 0x1
        mov edi, 0x2
        mov rax, 0x29 # socket syscall
        syscall

        mov dword ptr [rbp - 0x4], eax

        #bind a socket
        mov word ptr [rbp - 0x20], 0x2
        mov word ptr[rbp - 0x1e], 0x5000
        mov dword ptr[rbp - 0x1c], 0x0
        mov qword ptr[rbp - 0x19], 0x0

        lea rcx, [rbp - 0x20]
        mov edx, 0x10
        mov rsi, rcx
        mov edi, eax
        mov rax, 49
        syscall

        # listen
        mov esi, 0x0
        mov edi, dword ptr[rbp - 0x4]
        mov rax, 50
        syscall

.L0:
        # accept
        mov rdx, 0x0
        mov rsi, 0x0
        mov edi, dword ptr [rbp- 0x4]
        mov rax, 0x2b
        syscall

        mov dword ptr[rbp - 0x8], eax

		# fork
		mov rax, 57
		syscall

		test eax, eax
		jnz .L1

        #close socket
        mov edi, dword ptr[rbp - 0x4]
        mov rax, 0x03
        syscall

        # read
        mov rdx, 0x400
        sub rsp, 0x400
        lea rsi, [rsp]
        mov edi, dword ptr[rbp - 0x8]
        mov rax, 0
        syscall

		mov dword ptr[rbp - 0xc], eax

		lea rdi, [rsp]
		call is_get
		cmp rax, 0
		jne .L11

		#call get request handler function
		lea rdi, [rsp]
		mov esi, dword ptr[rbp - 0x8]
		call get_req
		jmp .L12
.L11:
		# call post request handler function
		lea rdi, [rsp]
		mov esi, dword ptr[rbp - 0xc]
		mov edx, dword ptr[rbp - 0x8]
		call post_req
.L12:
        # exit
        mov rdi, 0
        mov rax, 0x3c
        syscall
.L1:
        #close accept socket
        mov edi, dword ptr[rbp - 0x8]
        mov rax, 0x03
        syscall
        jmp .L0

is_get:
		push rbp
		mov rbp, rsp
		mov al, byte ptr[rdi]
		cmp al, 'G'
		jne .L9
		mov al, byte ptr[rdi + 1]
		cmp al, 'E'
		jne .L9
		mov al, byte ptr[rdi + 2]
		cmp al, 'T'
		jne .L9
		mov rax, 0
		leave
		ret
.L9:	
		mov rax, 1
		leave
		ret
		

get_req:
		push rbp
		mov rbp, rsp
		sub rsp, 0x1020

        # get file name
		mov qword ptr[rbp-0x8], rdi # buffer addr
		mov dword ptr[rbp-0xc], esi # accept fd


        call parse_file_name

        # open file
        mov rdx, 0
        mov rsi, 0
        mov rdi, rax
        mov rax, 0x2
        syscall

        mov dword ptr [rbp-0x10], eax

        # read file
        mov edx, 0x1000
        lea rsi, [rbp-0x1020]
        mov edi, dword ptr[rbp-0x10]
        mov rax, 0x0
        syscall

        mov dword ptr[rbp-0x14], eax

        # close file
        mov edi, dword ptr[rbp-0x10]
        mov rax, 0x03
        syscall

        #write
        mov rdx, 19
        lea rsi, http_response
        mov edi, dword ptr[rbp - 0xc]
        mov rax, 0x01
        syscall

        #write file content
        mov edx, dword ptr[rbp -0x14]
        lea rsi, [rbp-0x1020]
        mov edi, dword ptr[rbp - 0xc]
        mov rax, 0x01
        syscall
		leave
		ret



post_req:
		push rbp
		mov rbp, rsp
		sub rsp, 0x20

        # get file name
		mov qword ptr[rbp-0x8], rdi # buffer addr
		mov dword ptr[rbp-0xc], esi # buffer_len
		mov dword ptr[rbp-0x10], edx # accept fd cfd


        call parse_file_name

        # open file
        mov rdx, 0x1FF
        mov rsi, 0x41
        mov rdi, rax
        mov rax, 0x2
        syscall

        mov dword ptr [rbp-0x14], eax # file fd

		# Get content
		xor rbx, rbx
		xor rcx, rcx
		mov ecx, dword ptr[rbp-0xc]
		mov rdi, qword ptr[rbp-0x8]
		dec rcx

.L13:
		mov bl, byte ptr[rdi + rcx]
		cmp bl, 0x0A
		je .L14
		dec ecx
		jmp .L13
.L14:
		inc rcx
        # write to file
		mov edx, dword ptr[rbp-0xc]
		sub edx, ecx
		lea rsi, [rdi]
		add rsi, rcx
		mov edi, dword ptr[rbp - 0x14]
		mov rax, 0x1
		syscall

        # close file
        mov edi, dword ptr[rbp-0x14]
        mov rax, 0x3
        syscall

        # write to socket
        mov rdx, 0x13
        lea rsi, http_response
        mov edi, dword ptr[rbp - 0x10]
        mov rax, 0x1
        syscall

		leave
		ret


parse_file_name:
        push rbp
        mov rbp, rsp
        sub rsp, 0x20
        xor rbx, rbx
        xor rcx, rcx
        xor rdx, rdx
.L5:
        mov bl, byte ptr[rdi + rcx]
        cmp bl, 0x20
        je .L6
        inc rcx
        jmp .L5
.L6:
        inc rcx
        lea rax, [rdi + rcx]
.L7:
        mov bl, byte ptr[rdi + rcx]
        cmp bl, 0x20
        je .L8
        inc rcx
        jmp .L7

.L8:
        mov byte ptr[rdi + rcx], 0x0
        leave
        ret
