;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;very simple jwasm gtk example (written by jcfuller)
; create a Linux binary
; 1. assemble:       jwasm -elf -zcw -Fo=gtk01.o gtk01.asm
; 2. link with LD:   ld -s -o gtk01 gtk01.o -I/lib/ld-linux.so.2 `pkg-config --libs gtk+-2.0`
;
; create a Win32 binary with MinGW
; ( MinGW installed at C:\MinGW, GTK+ installed at C:\GTK )
; 1. assemble:       jwasm -elf gtk01.asm
; 2. link with LD:   ld -s -o gtk01.exe gtk01.obj -Lc:/gtk/lib 
;                    -lgtk-win32-2.0.dll -lgobject-2.0.dll -Lc:/mingw/lib -lmsvcrt
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
    .386
    .model flat

    public _start

gtk_init proto c :DWORD, :DWORD
gtk_init_check proto c :DWORD, :DWORD
gtk_window_new proto c :DWORD
gtk_window_set_title proto c :DWORD, :DWORD
gtk_table_new proto c :DWORD, :DWORD, :DWORD
gtk_table_attach_defaults proto c :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
gtk_container_add proto c :DWORD, :DWORD
gtk_button_new_from_stock  proto c :DWORD
gtk_label_new proto c :DWORD
gtk_widget_show_all proto c :DWORD
gtk_main proto c
gtk_main_quit proto c
g_signal_connect_data proto c :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

puts  proto c :DWORD
exit  proto c :DWORD

.data
no_int db 'No gtk_init',0
wincap db 'Hello World', 0
labelcap db 'jwasm gtk example', 0
quitbut db 'gtk-quit',0
no_win_err db 'No Window',0
sdel_event db 'delete-event',0
sclicked db 'clicked',0

    .data?
window dd ?
table dd ?
gtklabel dd ?
button dd ?

    .code

_start:    ; let the ritual begin.

;make sure we have gtk
invoke gtk_init_check,0,0
.if (eax == 0)
    invoke puts, offset no_int
    jmp Terminate
.endif
;create window
invoke gtk_window_new, 0
.if (eax == 0)
    invoke puts, offset no_win_err
    jmp Terminate
.endif
mov [window], eax

invoke gtk_window_set_title,[window], offset wincap
invoke gtk_table_new,15, 15, 1
mov [table],eax
invoke gtk_container_add,[window],[table]
invoke gtk_label_new,offset labelcap
mov [gtklabel],eax
invoke gtk_table_attach_defaults,[table],[gtklabel],1, 8, 3, 7
invoke gtk_button_new_from_stock,offset quitbut
mov [button],eax
invoke gtk_table_attach_defaults,[table],[button], 10, 14, 12, 14
;Show whole GUI
invoke gtk_widget_show_all,[window]
;attache signals
invoke g_signal_connect_data,[window],offset sdel_event,offset exit_prog,0, 0, 0
invoke g_signal_connect_data,[button],offset sclicked,offset exit_prog,0, 0, 0
;Do it
invoke gtk_main
;------------------------------------------------------------------------------
;Callback for closing window
exit_prog proc
    invoke gtk_main_quit
exit_prog endp
;------------------------------------------------------------------------------
Terminate:
    invoke exit, 0

    end _start
