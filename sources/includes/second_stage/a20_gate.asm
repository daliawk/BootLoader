check_a20_gate:
        pusha                   ;Saving all general purpose registers on the stack
        mov si, a20_enabled_msg

        ;INT 0x15 Function 0x2402 checks A20 gate
        mov ax,0x2402
        int 0x15
        jc .error               ;In case of error occuring
        cmp al,0x0              ;If al == 0, then A20 is disabled and we need to enable it, else exit
        jne .exit

        .enable_a20:
                mov si, a20_not_enabled_msg
                call bios_print

                ;INT 0x15 Function 0x2401 enables A20 gate
                mov ax,0x2401
                int 0x15
                jc .error                       ;In case of error occuring
                jmp check_a20_gate              ;Else, recheck that the gate has been enabled
        
        .error:
                cmp ah, 0x1                     ;If ah==1, then keyboard controller is in secure mode or unavailable
                je .secure_mode_error

                cmp ah, 0x86                    ;If ah==0x86, then the function is not supported
                je .function_not_supported

                mov si, unknown_a20_error       ;Else, the error is unknown
                call bios_print

                call hang
        
        .secure_mode_error:
                mov si, keyboard_controller_error_msg
                call bios_print
                call hang

        .function_not_supported:
                mov si, a20_function_not_supported_msg
                call bios_print
                call hang

        
        .exit:
                call bios_print
                popa            ;Restoring all general purpose registers from the stack
                ret