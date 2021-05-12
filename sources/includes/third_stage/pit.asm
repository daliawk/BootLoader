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
            
      mov rdi,[pit_counter]         ; Value to be printed in hexa
      call video_print_hexa          ; Print pit_counter in hexa

      ; Moving to the next line on the screen
      mov rsi, end_line
      call video_print

      .increment:
      inc qword [pit_counter]       ; Increment pit_counter

      popaq
ret



configure_pit:
    pushaq
      ; This function need to be written by you.
      mov rdi,32 ; PIT is connected to IRQ0 -> Interrupt 32
      mov rsi, handle_pit ; The handle_pit is the subroutine that will be invoked when PIT fires
      call register_idt_handler ; We register handle_pit to be invoked through IRQ32
      mov al,00110110b ; Set PIT Command Register 00 -> Channel 0, 11 -> Write lo,hi bytes, 011 -> Mode 3, 0-> Bin
      out PIT_COMMAND,al ; Write command port
      xor rdx,rdx ; Zero out RDX for division
      mov rcx,50
      mov rax,1193180 ; 1.193180 MHz
      div rcx ; Calculate divider -> 11931280/50 Divide RDX:RAX/RCX, RDX contains the remainder → after the operation
      out PIT_DATA0,al ; Write low byte to channel 0 data port
      mov al,ah ; Copy high byte to AL
      out PIT_DATA0,al ; Write high byte to channel 0 data port
    popaq
    ret