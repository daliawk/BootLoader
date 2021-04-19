;************************************** load_boot_drive_params.asm **************************************
      load_boot_drive_params:        ;A subroutine to read the [boot_drive] parameters and update [hpc] and [spt]
            pusha                    ;Saving all general purpose registers on the stack
            
            ;If es:di do not contain zeros, unexpected behavior will happen
            xor di,di 
            mov es,di

            ;INT 0x13 Function 0x8 --> Fetches disk parameters
            mov ah,0x8 
            mov dl,[boot_drive]      ;Getting the disk number 
            int 0x13 
            
            ;dh contains the index of last head (base 0)
            ;cx --> bit 0 to 5 --> Index of the last sector (base 1)
            ;       bit 6 to 15 --> Index of last cylinder (base 0)
            ;ah --> error code if carry flag
            
            inc dh                   ;To get head per cylinder, we increment index of last head since it is 0-based
            mov word [hpc],0x0 
            mov [hpc+1],dh           ;Store dh into the lower byte of the of [hpc] since hpc is a word
            and cx,0000000000111111b ;Extracting bit 0 to 5
            mov word [spt],cx 
            popa                     ;Restore all general purpose registers from the stack
            ret