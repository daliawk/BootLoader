[ORG 0x7c00]      ; Since this code will be loaded at 0x7c00 we need all the addresses to be relative to 0x7c00
                  ; The ORG directive tells the linker to generate all addresses relative to 0x7c00

;********************************* Main Program **************************************
      xor ax, ax        ; Initialize ax to zero.
      mov ds, ax        ; store 0 in DS to set data segment to 0x0000.
      mov si, msg       ; store the address of the string msg into si so we can use lodsb later.
      call bios_print   ; Call the bios_print subroutine to print msg on the screen. 
                        ; This will push the next address on the stack first.
      hang:             ; An infinite loop just in case interrupts are enabled. More on that later.
            hlt         ; Halt will suspend the execution. This will not return unless the processor got interrupted.
            jmp hang    ; Jump to hang so we can halt again.
;************************************* Data ******************************************
      msg   db 'Hello World Boot Loader for CSCE-231 -:)', 13, 10, 0 
      ; Notice that we have added "13,10" as the carriage return character code "\r\n".
      ; Then we add a NULL character, "0", as an indication for the end of the string.
;**************************** Subroutines/Functions **********************************

      bios_print:       ; A subroutine to print a string on the screen using the bios int 0x10.
                        ; Expects si to have the address of the string to be printed.
                        ; Will loop on the string characters, printing one by one. 
                        ; Will Stop when encountering character 0.
            .print_loop:      ; Loop local label
                  xor ax,ax         ; Initialize ax to zero
                  lodsb             ; Load byte/char pointed to by si to al and increment si
                  or al, al         ; Check of al contains the value zero; if yes the zero flag will be set.
                  jz .done          ; Check the zero flag and jump to the label "done" if set
                                    ; Else print the character in al
                  mov ah, 0x0E      ; INT 0x10 print character function
                  int 0x10          ; Print character loaded in al. al is already loaded with the character
                  jmp .print_loop   ; Loop to process next character
                  .done:            ; Loop exit label
                        ret         ; End Subroutine; popup return address on the stack and set PC register to it
;**************************** Padding and Signature **********************************
      times 510-($-$$) db 0   ; $$ refers to the start address of the current section, $ refers to the current address.
                              ; ($-$$) is the size of the above code/data
                              ; times take a count and a data item and repeat it as many time as the value of count.
                              ; We subtract ($-$$) from 510 and use "times" to fill in the rest of the 510 with zero bytes.
                              ; We use 510 instead of 512 to reserve the last two bytes for the signature below. 
      db 0x55,0xAA            ; Boot sector MBR signature
