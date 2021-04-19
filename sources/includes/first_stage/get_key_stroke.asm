;************************************** get_key_stroke.asm **************************************      
        get_key_stroke: ; A routine to print a confirmation message and wait for key press to jump to second boot stage

                pusha           ;Save all general purpose registers on the stack
                
                mov si, key_stroke_msg
                call bios_print
                
                ;INT 0x16 Function 0x0 waits for a key stroke
                mov ah,0x0 
                int 0x16 
                
                popa            ;Restore all general purpose registers from the stack
                ret