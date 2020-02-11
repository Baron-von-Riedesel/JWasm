;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;very simply ncurses example borrowed from FreeBASIC
;ported to jwasm 12-01-2009 
;James C. Fuller
;------------------------------------------------------------------------------
;JWASM -elf -zcw -Fo ncurs1.o ncurs1.asm
;gcc  -o ncurs1 ncurs1.o -I/lib/ld-linux.so.2 -lncurses
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    .486
    .model flat,c
    option casemap:none

initscr         proto 
newwin          proto :DWORD,:DWORD,:DWORD,:DWORD
delwin          proto :DWORD
box             proto :DWORD,:DWORD,:DWORD
endwin          proto 
wrefresh        proto :DWORD
curs_set        proto :DWORD
wgetch          proto :DWORD
mvwprintw       proto :DWORD,:DWORD,:DWORD,:DWORD,:VARARG
wclear          proto :DWORD 
cbreak          proto
noecho          proto
COLOR_PAIR      proto :DWORD
has_colors      proto
start_color     proto
pair_content    proto :WORD,:DWORD,:DWORD
printw          proto :DWORD,:VARARG
init_pair       proto :WORD,:WORD,:WORD
attrset         proto :DWORD
getch           proto
printf          proto c :DWORD,:VARARG

COLOR_BLACK     equ 0
COLOR_RED       equ 1
COLOR_GREEN     equ 2
COLOR_YELLOW    equ 3
COLOR_BLUE      equ 4
COLOR_MAGENTA   equ 5
COLOR_CYAN      equ 6
COLOR_WHITE     equ 7

;------------------------------------------------------------------------------
lf equ 10

CStr macro text:vararg
local xxx
    .const
xxx db text,0
    .code
    exitm <offset xxx>
    endm
;------------------------------------------------------------------------------
    .code

main proc

    local window:DWORD,f:WORD,b:WORD

    invoke initscr
    invoke cbreak
    invoke noecho
    invoke has_colors
    .if eax == 0
        invoke printf,CStr("This demo requires a color terminal",lf)
        jmp @F
    .endif
    invoke start_color
    invoke pair_content,0,ADDR f,ADDR b
    invoke printw,CStr("pair 0 contains (%d,%d) Any key to continue",lf), f, b
    invoke getch
    invoke printw, CStr("Initializing pair 1 to red/black",lf)
    invoke init_pair,1,COLOR_RED, COLOR_BLACK
    invoke COLOR_PAIR,1
    invoke attrset,eax
    invoke printw,CStr("RED/BLACK -> Any Key To continue",lf)
    invoke getch
    invoke COLOR_PAIR,0
    invoke attrset,eax 
    invoke printw,CStr("Initializing pair 2 to white/blue",lf)
    invoke init_pair,2,COLOR_WHITE, COLOR_BLUE
    invoke COLOR_PAIR,2
    invoke attrset,eax
    invoke printw,CStr("WHITE/BLUE -> Any Key To continue",lf)
    invoke COLOR_PAIR,0
    invoke attrset,eax 
    invoke getch
    invoke printw,CStr("Initializing pair 3 to white/cyan",lf)
    invoke init_pair,3,COLOR_WHITE, COLOR_CYAN
    invoke COLOR_PAIR,3
    invoke attrset,eax 
    invoke printw,CStr("WHITE/CYAN -> Any Key To continue",lf)
    invoke getch

    invoke endwin
@@:
    ret
main endp
end
