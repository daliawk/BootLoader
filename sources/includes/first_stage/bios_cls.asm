;************************************** bios_cls.asm **************************************      
      bios_cls:         ;A routine to initialize video mode 80x25 which also clears the screen
            pusha       ;Pushing all general purpose registers to stack

            ;INT 0x10 Function 0x0 --> Video Mode Function
            mov ah,0x0  
            mov al,0x3  ;80x25 16 color text mode
            int 0x10    
            
            popa        ;Return all general purpose registers from the stack as they were
            ret
