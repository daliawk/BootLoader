      bios_print_hexa:  ; A routine to print a 16-bit value stored in di in hexa decimal (4 hexa digits)
            pusha                               ; Saving all general purpose registers on the stack
            mov cx,0x8                          ; Set loop counter for 4 iterations, one for each digit
            mov ebx,edi                         ; DI has the value to be printed and we move it to bx so we do not change it
            .loop:                              ; Loop on all 4 digits
                  mov esi,ebx                   ; Move current bx into si
                  and esi,0xF0000000            ; Extract the first left most hexa digits (4 bits)
                  shr esi,0x1c                  ; Shift SI 12 bits right 
                  mov al,[hexa_digits+esi]      ; get the right hexadcimal digit from the array           
                  mov ah, 0x0E                  ; INT 0x10 print character function
                  int 0x10                      ; Print character
                  shl ebx,0x4                   ; Shift bx 4 bits left so the next digits is in the right place to be processed
                  dec cx                        ; decrement loop counter
                  cmp cx,0x0                    ; compare loop counter with zero.
                  jg .loop                      ; Loop again we did not yet finish the 4 digits
            popa                                ; Restore all general purpose registers from the stack
            ret


      bios_print_hexa_with_prefix:  ; A routine to print a 16-bit value stored in di in hexa decimal (4 hexa digits)
            pusha                               ; Save all general purpose registers on the stack
            mov si,hexa_prefix                  ; Print the hexadecimal prefix "0x"
            call bios_print                                 
            call bios_print_hexa
            popa                                ; Restore all general purpose registers from the stack
            ret
