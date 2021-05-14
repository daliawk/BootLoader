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

  ; Check if the counter is divisible by 1000
  cmp rdx, 0
  jne .increment
  
  ; If yes, print the counter in a new line
  mov rdi,[pit_counter]          
  call video_print_hexa          

  ; Moving to a new line on the screen
  mov rsi, end_line
  call video_print

  .increment:
    inc qword [pit_counter]       ; Increment pit_counter

  popaq
ret



configure_pit:
  pushaq
  
  ; Registering the PIT IDT handler
  mov rdi,32          ; Interrupt 32 (IRQ0)
  mov rsi, handle_pit ; The handle_pit is the subroutine that will be invoked when PIT fires
  call register_idt_handler ; We register handle_pit to be invoked through IRQ32

  ; Setting the PIT Command Register
  mov al,00110110b    ; Bit 0: 0      (The value in the counter is binary)
                      ; Bits 1-3: 011 (Mode 3)
                      ; Bits 4-5: 11  (Write to lo and hi bytes)
                      ; Bits 6-7: 00  (Channel 0)
  out PIT_COMMAND,al 

  ; Obtaining 50 interrupts per second
  xor rdx,rdx 
  mov rcx,50
  mov rax,1193180 ; The frequency
  div rcx 

  ; Writing ax to the data port
  out PIT_DATA0,al
  mov al, ah 
  out PIT_DATA0,al
  popaq
ret