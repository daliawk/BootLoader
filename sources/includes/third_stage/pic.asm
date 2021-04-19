%define MASTER_PIC_COMMAND_PORT     0x20
%define SLAVE_PIC_COMMAND_PORT      0xA0
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


    configure_pic:
        pushaq
                  ; This function need to be written by you.

        popaq
        ret


    set_irq_mask:
        pushaq                              ;Save general purpose registers on the stack
        ; This function need to be written by you.
        .out:    
        popaq
        ret


    clear_irq_mask:
        pushaq
        ; This function need to be written by you.
        .out:    
        popaq
        ret
