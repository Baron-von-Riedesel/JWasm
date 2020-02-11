
;--- a Win16 dll sample.
;--- assemble:
;---   jwasm win16_2d.asm
;--- link:
;---   link16 win16_2d.obj,,,,win16_2d.def

    .286
    .model small
    .386

    .data

wVar dw 0

    .code

LibMain proc far pascal

    mov ax,1
    ret
LibMain endp

;--- Windows Exit Procedure.

WEP proc far pascal wCode:word

    mov ax,1
    ret
WEP endp

;--- first exported function: stores value
;--- in wVar.

Export1 proc far pascal uses ds value:word

    mov ax,dgroup
    mov ds,ax
    mov ax,value
    mov wVar,ax
    ret
Export1 endp

;--- second exported function: returns value
;--- in wVar.

Export2 proc far pascal uses ds

    mov ax,dgroup
    mov ds,ax
    mov ax,wVar
    ret
Export2 endp

    END LibMain
