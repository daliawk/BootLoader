%define MASTER_PIC_COMMAND_PORT     0x20    
%define SLAVE_PIC_COMMAND_PORT      0xA0    
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


    disable_pic:    ;Writing 0xFF to the PIC's data ports will disable it
        pusha
        mov al,0xFF
        out MASTER_PIC_DATA_PORT,al
        out SLAVE_PIC_DATA_PORT,al
        nop
        nop
        mov si, pic_disabled_msg
        call bios_print
        popa
        ret