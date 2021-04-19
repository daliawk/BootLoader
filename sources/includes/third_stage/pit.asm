%define PIT_DATA0       0x40
%define PIT_DATA1       0x41
%define PIT_DATA2       0x42
%define PIT_COMMAND     0x43

pit_counter dq    0x0               ; A variable for counting the PIT ticks

handle_pit:
      pushaq
            mov rdi,[pit_counter]         ; Value to be printed in hexa
            push qword [start_location]
            mov qword [start_location],0
            call bios_print_hexa          ; Print pit_counter in hexa
            pop qword [start_location]
            inc qword [pit_counter]       ; Increment pit_counter
      popaq
      ret



configure_pit:
    pushaq
      ; This function need to be written by you.
    popaq
    ret