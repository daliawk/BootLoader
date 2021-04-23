%define CODE_SEG     0x0008         ; Code segment selector in GDT
%define DATA_SEG     0x0010         ; Data segment selector in GDT
%define PAGE_TABLE_EFFECTIVE_ADDRESS 0x1000


switch_to_long_mode:

    ; This function need to be written by you.
    

    ; Setting cr4
    ; Set the PAE and PGE bits (bit 5 and 7).
    mov eax, 10100000b
    ; Store eax into CR4
    or cr4, eax

    ; Setting cr3
    mov edi,PAGE_TABLE_EFFECTIVE_ADDRESS
    mov cr3, edi ; Point CR3 at the PML4.


    ; Read from the EFER (Extended Feature Enable Register)
    ; MSR. (Model Specific Register). 0xC0000080 is the EFER
    ; register identifier which need to be store in EAX.
    ; The value of the register is read into EDX:EAX
    mov ecx, 0xC0000080
    rdmsr
    ; We will modifying bit # 8 so we will not touch EDX
    ; We will only modify bit 8 in EAX and write back EDX:EAX
    or eax, 0x00000100 ; Set the LME bit. (Long Mode Enabled BIT # 8)
    wrmsr

    ; Setting cr0
    mov ebx, cr0 ; Read CR0
    or ebx,0x80000001 ; Set Bit 0 and 31
    ; Bit 0 to set protected mode
    ; Bit 31 for enabling Paging
    mov cr0, ebx ; Set CR0

    
    lgdt [GDT64.Pointer]            ; Loading GDT with GDT.Pointer
    jmp CODE_SEG:LongModeEntry      ; Jumping to 64 bit mode

    ret