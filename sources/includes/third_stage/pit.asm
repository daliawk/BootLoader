%define PIT_DATA0       0x40
%define PIT_DATA1       0x41
%define PIT_DATA2       0x42
%define PIT_COMMAND     0x43

pit_counter dq    0x0               ; A variable for counting the PIT ticks
end_line db 13, 0

handle_pit:
  pushaq
  mov rax, [pit_counter]
  mov r8, 1000
  div r8

  cmp rdx, 0
  jne .increment

  ; Printing the counter          
  mov rdi,[pit_counter]         
  call video_print_hexa          

  ; Moving to the next line on the screen
  mov rsi, end_line
  call video_print

  .increment:
    inc qword [pit_counter]       ; Increment pit_counter

  popaq
ret



configure_pit:
  pushaq
  
  ; Registering the PIT handler to be invoked through IRQ0
  mov rdi,32                  ; Interrupt 32 (IRQ0)
  mov rsi, handle_pit         ; The address of the subroutine to be invoked when the PIT produces an interrupt
  call register_idt_handler 

  ; Setting the PIT Comman Register
  mov al,00110110b            ; Bits 6-7 = 00  (Channel 0)
                              ; Bits 4-5 = 11  (Writing to both lo and hi bytes)
                              ; Bits 1-3 = 011 (Mode 3)
                              ; Bit   0  = 0   (The value in the counter is binary)
  out PIT_COMMAND,al          

  ; Setting the the PIT to produce 50 interrupts per second
  xor rdx,rdx 
  mov rcx,50
  mov rax,1193180             ; The frequencye
  div rcx                     ; Dividing the frequency

  ; Writing the quotient to Channel 0 data port
  out PIT_DATA0,al 
  mov al,ah 
  out PIT_DATA0,al 
  
  popaq
ret