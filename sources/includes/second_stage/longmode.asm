%define CODE_SEG     0x0008         ; Code segment selector in GDT
%define DATA_SEG     0x0010         ; Data segment selector in GDT


switch_to_long_mode:

    ; This function need to be written by you.
    
    ; Set CRs and EFER
    
    lgdt [GDT64.Pointer]            ; Loading GDT with GDT.Pointer
    jmp CODE_SEG:LongModeEntry      ; Jumping to 64 bit mode

    ret