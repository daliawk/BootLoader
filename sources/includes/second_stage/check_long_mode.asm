    check_long_mode:
        pusha                               ; Save all general purpose registers on the stack
        call check_cpuid_support            ; Check if cpuid instruction is supported by the CPU
        call check_long_mode_with_cpuid     ; check long mode using cpuid
        popa                                ; Restore all general purpose registers from the stack
        ret

    check_cpuid_support:
        pusha                               ;Saving all general purpose registers on the stack

        pushfd                              ;Saving eflags
        pushfd                              ;Storing a copy of the eflags for comparison
        pushfd                              ;Getting a copy of the eflags to be changed
        pop eax
        xor eax,0x0200000                   ;Changing the value of bit 21
        push eax                            ;Pushing the modified eflags
        popfd                               ;Moving the modified value of the eflags to the eflags register
        pushfd                              ;Getting the current value of the eflages in eax
        pop eax
        pop ecx                             ;Getting the original eflags
        
        ;If the eflags has been modified, the output of xoring the old and new eflags will give all zeros with the exception of bit 21
        xor eax,ecx                         
        and eax,0x0200000                   ;Getting bit 21
        cmp eax,0x0                         ;If bit 21 is zero, then the eflags were not modified which means that cpuid is not supported
        jne .cpuid_supported            
        
        mov si,cpuid_not_supported 
        call bios_print
        jmp hang

        .cpuid_supported:
            mov si,cpuid_supported
            call bios_print
            
            popfd                           ;Restoring original eflags
            popa                            ;Restoring all general purpose registers from the stack
            ret

    check_long_mode_with_cpuid:
        pusha                               ;Saving all general purpose registers on the stack

        mov eax,0x80000000                  ;cpuid function to get the largest function number
        cpuid                               ;The largest function number is stored in eax
        cmp eax,0x80000001                  ;Checking if 0x80000001 is bigger than the largest function number which means it is not supported
        jl .long_mode_not_supported 
        
        ;Using cpuid function 0x80000001 to get extended feature bits
        mov eax,0x80000001                  
        cpuid                               ;The processor extended feature bits are in edx
        and edx,0x20000000                  ;Getting bit 29 which signifies the long mode
        cmp edx,0                           ;If bit 29 is zero them long mode is not supported
        je .long_mode_not_supported 
        
        ;Else, it is supported
        mov si,long_mode_supported_msg 
        call bios_print
        jmp .exit_check_long_mode_with_cpuid 
        
        .long_mode_not_supported:
            mov si,long_mode_not_supported_msg 
            call bios_print 
            jmp hang
        
        .exit_check_long_mode_with_cpuid:
            popa                                ; Restore all general purpose registers from the stack
            ret