;************************************** bios_print.asm **************************************      
      bios_print:       ; A subroutine to print a string on the screen using the bios int 0x10.
                        ; Expects si to have the address of the string to be printed.
                        ; Will loop on the string characters, printing one by one. 
                        ; Will Stop when encountering character 0. 
            
            pusha                   ;Pushing all general purpose registers on the stack

            .print_loop:            ;Loop over each character in string
                  xor ax,ax         ;Zero ax
                  lodsb             ;Loading to al the character at the address in si then increment si
                  or al, al         ;If al contains the value zero, exit loop
                  jz .exit
                  
                  ;INT 0x10 Function 0x0E --> Prints character in al
                  mov ah, 0x0E      
                  int 0x10          
                  jmp .print_loop   ;Loop to process next character
                  
                  .exit:
                        popa        ;Returning all general purpose registers from the stack
                        ret
