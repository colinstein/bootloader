; This is a super minimal "hello world" bootloader for x86 PCs
; You can compile this with nasm:
;
;   $ nasm -f bin -o bootloader.img bootloader.asm
;
; You can write it to disk with
;
;   $ dd if=bootloader.img of=/dev/sda0 bs=512 count=1
;
; be warned that this doesn't really work on UEFI systems unless you've turned
; on CSM for BIOS-compatible booting. You can however set VMWare or some other
; emulator to use the bootloader.img as a floppy disk image and boot a pretend
; system that way.

; The program expects to be loaded at 0x7C00h, but that's ultimately up to the
; BIOS to where it ends up. Settings org allows us to use labels, where using
; org 0 and then setting ds to 0x7c00 manually may not work.
          org 0x7C00

; When the CPU starts up it's going to be in 16-bit real mode so we need to
; let the compiler know that, otherwise we're likely to get somethign that isn't
; going to work properly
          bits 16

; This jumps over the data to the start of our actual program. Because all of
; the data and the halt are at the end of our program, we don't actually have
; to call this. If you had more routines or made your message db here then it
; would be necessary.
; jmp start

; Here's where the magic starts.
start:

; First, disable all interupts.
          cli

; Next, move the location of the first letter in our message into the source-
; index. First we'll set the data segment (ds) to 0.

; there's a convention to get a 0 this way instead of using mov.
          xor dx, dx
; and now we set the data segment to 0.
          mov ds, ax

; This might be a good place to set the cursor position and colors before the
; bios interupt below. see this page for some details:
; https://en.wikipedia.org/wiki/BIOS_interrupt_call

; We're going to start printing so clear the direction flag. It shouldn't be
; weird but let's just be sure.
          cld

; and then we'll set the source index to 0 so it points at the first letter in
; the message we want to print.
          mov si, msg

; When you call the interupt, it's going to look in AH to figure out what
; This is the write character in TTY mode. You could also try the character
; print routine 9h if you do the colour/postion tricks above.
          mov ah, 0x0E

; this is our character-by-character print loop. Unfortunately we don't have an
; equivalent to a printf so we have to do each character one at a time.
; Fortunately there's the lodsb that will push our character into AL and update
; the source index SI for us.
; Read the character from DS:SI into AL, then increment SI so that's pointing
; at the next character when we loop around.
.loop     lodsb

; Check if we've loaded the null into al - if so that indicates we've reached
; the end of our string.

; There's a convention to do it this way, but cmp al, 0 is similar
          or al, al

; Jump if the comparison above is zero, go to our quit section.
; if you'd use the cmp, then you'd want to je instead.
; if we've loaded a null character then it's time to quit, we're done
          jz quit

; If not, the we can print our character. The TTY printing service
; automatically advances the cursor so there isn't maintenance of cursor
; position to do.
          int 0x10

; Time to go around again and print the next character.
          jmp .loop

; This is just a hard halt. It's not the best way to exit our loader, but it's
; good enough for a "hello world" proof of concept.
quit:     hlt

; This is our simple "hello world message", the extra 0 markes the end of the
; string. We'll use that to control our loop later on by checking for when lodsb
; pushes a null into al.
msg:      db "Colin loves you", 0

; The bootloader must be 512 bytes long. The last two bytes must be 0xAA and
; 0x55 as a signature. To make sure that happens we'll write zeros.
;  - 512 times
;  - minus - 2 (for the signature bytes)
;  - minus the length of the program
; The program length is from $ (the current line) minus $$ (first instruction)
times     0x200 - 2 - ($ - $$) db 0

; And finally we append our signature
dw        0xAA55
