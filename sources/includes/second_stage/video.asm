%define VIDEO_BUFFER_SEGMENT                    0xB000
%define VIDEO_BUFFER_OFFSET                     0x8000
%define VIDEO_BUFFER_EFFECTIVE_ADDRESS          0xB8000
%define VIDEO_SIZE      0X0FA0    ; 25*80*2
    video_cls_16:
            pusha                                   ; Save all general purpose registers on the stack

                  ; This function need to be written by you.

            popa                                ; Restore all general purpose registers from the stack
            ret

