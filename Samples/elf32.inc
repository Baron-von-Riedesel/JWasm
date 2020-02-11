;------------------------------------------------------------------------------
;
;   ELF32 executable Binary Macro for JWasm.
;   Written by Ito Toshimitsu.
;
;   Purpose: to create a binary in ELF format using JWasm's -bin switch.
;
;------------------------------------------------------------------------------

; ELF Type
ELF_Linux   equ 3
ELF_FreeBSD equ 9

; The ELF32 header macro
elf32_header macro elf_type, start
_elf_phdr_flags equ     7
    org     08048000h

_elf_start:
    db      7Fh, 'ELF'              ; e_ident
    db      1, 1, 1, elf_type
    db      8 dup(0)
    dw      2                       ; e_type : Executable file
    dw      3                       ; e_machine : Intel 80386
    dd      1                       ; e_version : Current Version
    dd      offset start            ; e_entry
    dd      offset _phdr - offset _elf_start  ; e_phoff (program header offset)
    dd      0                       ; e_shoff (section header offset)
    dd      0                       ; e_flags (Processor-Specific flags)
    dw      34h                     ; e_ehsize (ELF header's size)
    dw      20h                     ; e_phentsize
_phdr:
    dw      1                       ; e_phnum (program header entries number)
    dw      0                       ; e_shentsize (section header's size)
    dw      0                       ; e_shnum (section header entries number)
    dw      0                       ; e_shstrndx
    dd      offset _elf_start       ; p_vaddr (virtual address)
    dd      offset _elf_start       ; p_paddr
    dd      _elf_filesize           ; p_filesz
    dd      _elf_filesize           ; p_memsz
    dd      _elf_phdr_flags
    dd      1000h                   ; p_align
    endm

; The ELF32 footer macro
elf32_footer    macro
_elf_filesize     equ     $ - offset _elf_start
    endm
