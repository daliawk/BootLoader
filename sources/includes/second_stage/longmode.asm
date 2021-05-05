%define CODE_SEG     0x0008         ; Code segment selector in GDT
%define DATA_SEG     0x0010         ; Data segment selector in GDT
%define PAGE_TABLE_EFFECTIVE_ADDRESS 0x1000


switch_to_long_mode:

    ; Setting the PAE and PGE bits in CR4.
    mov eax, 10100000b
    mov ebx, cr4
    or eax, ebx                 ; Setting bits 5 and 7
    mov cr4, eax

    ; Setting cr3 with the Page Table's address (PML4's address)
    mov edi,PAGE_TABLE_EFFECTIVE_ADDRESS
    mov cr3, edi 


    ; Configuring the Long Mode Enabled bit in EFER
    mov ecx, 0xC0000080         ; Loading ecx with the EFER register identifier
    rdmsr                       ; Reading the EFER into eax
    or eax, 0x00000100          ; Seting bit 8 (LME bit) 
    wrmsr                       ; Writing the EFER back

    ; Enabling Protected mode and Paging
    mov ebx, cr0                ; Reading CR0
    or ebx,0x80000001           ; Seting Bit 0 (Protected Mode bit) and 31 (Paging bit)
    mov cr0, ebx 

    
    lgdt [GDT64.Pointer]        ; Loading GDT with the pointer of the GDT we created
    jmp CODE_SEG:LongModeEntry  ; Jumping to 64 bit mode

    ret