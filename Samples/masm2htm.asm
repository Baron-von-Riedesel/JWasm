
;--- Masm2Htm.asm
;--- simple masm source to html converter. Public Domain.
;--- it's a sample for a mixed-language application (uses CRT)

;--- Win32 binary:
;--- assemble: jwasm -coff masm2htm.asm crtexe.asm
;--- link:     link masm2htm.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;--- assemble: jwasm -zcw -elf -D?MSC=0 -Fo masm2htm.o masm2htm.asm
;--- link:     gcc -o masm2htm masm2htm.o

    .386
    .MODEL FLAT, c
    option casemap:none

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC     equ 1  ;0=use gcc, 1=use ms crt
endif

BG_COLOR     equ <E0E0E0>   ;background color
REGS_COLOR   equ <00B000>   ;register's text color
COM_COLOR    equ <808080>   ;comment's text color 
INST_COLOR   equ <0000E0>   ;instruction text color
OPTR_COLOR   equ <808000>   ;operator text color
TYPE_COLOR   equ <800000>   ;basic types text color

REGS_COLORED equ 1          ;if registers are to be colored
REGS64       equ 1          ;scan for amd64 registers?
INST_COLORED equ 1          ;if instructions are to be colored
OPTR_COLORED equ 1          ;if text operators are to be colored
TYPE_COLORED equ 1          ;if basic types are to be colored

printf  proto c :ptr BYTE, :VARARG
fopen   proto c :ptr BYTE, :ptr BYTE
fclose  proto c :ptr
fseek   proto c :ptr, :DWORD, :DWORD
ftell   proto c :ptr
fread   proto c :ptr BYTE, :DWORD, :DWORD, :ptr
fwrite  proto c :ptr BYTE, :DWORD, :DWORD, :ptr
strcat  proto c :ptr BYTE, :ptr BYTE
strcpy  proto c :ptr BYTE, :ptr BYTE
strlen  proto c :ptr BYTE
_stricmp  proto c :ptr BYTE, :ptr BYTE
malloc  proto c :DWORD
free    proto c :ptr

lf  equ 10
cr  equ 13

SEEK_SET equ 0
SEEK_END equ 2
NULL     equ 0
EOL      equ <cr,lf>

CStr macro text
local xxx
    .const
xxx db text,0
    .code
    exitm <offset xxx>
    endm

;--- errno access
ife ?USEDYN
externdef c errno:dword   ;errno is global var
else
__errno macro
;--- if errno is to be defined as a function call
 if ?MSC
_errno proto c            ;ms crt
    call _errno
 else
__errno_location proto c  ;gcc
    call __errno_location
 endif
    mov eax,[eax]
    exitm <eax>
    endm
errno textequ <__errno()>
endif

@DD macro list:VARARG
    for directive, <list>
local xxx
    .const
xxx db "&directive&",0
    .data
    dd offset xxx
    endm
    endm

    .data

;--- array of directives which are to be displayed "bold"

dirtab label dword
    @DD <.186>,      <.286>,      <.286c>,      <.286p>
    @DD <.287>,      <.386>,      <.386c>,      <.386p>
    @DD <.387>,      <.486>,      <.486p>,      <.586>
    @DD <.586p>,     <.686>,      <.686p>,      <.8086>
    @DD <.8087>,     <.allocstack>, <.alpha>,   <.break>
    @DD <.code>,     <.const>,    <.continue>,  <.cref>
    @DD <.data>,     <.data?>,    <.dosseg>,    <.else>
    @DD <.elseif>,   <.endif>,    <.endprolog>, <.endw>
    @DD <.err>,      <.err1>,     <.err2>,      <.errb>
    @DD <.errdef>,   <.errdif>,   <.errdifi>,   <.erre>
    @DD <.erridn>,   <.erridni>,  <.errnb>,     <.errndef>
    @DD <.errnz>,    <.exit>,     <.fardata>,   <.fardata?>
    @DD <.if>,       <.k3d>,      <.lall>,      <.lfcond>
    @DD <.list>,     <.listall>,  <.listif>,    <.listmacro>
    @DD <.listmacroall>, <.mmx>,  <.model>,     <.no87>
    @DD <.nocref>,   <.nolist>,   <.nolistif>,  <.nolistmacro>
    @DD <.pushframe>,<.pushreg>,  <.radix>,     <.repeat>
    @DD <.safeseh>,  <.sall>,     <.savereg>,   <.savexmm128>
    @DD <.seq>,      <.setframe>, <.sfcond>,    <.stack>
    @DD <.startup>,  <.tfcond>,   <.until>,     <.untilcxz>
    @DD <.while>,    <.x64>,      <.x64p>,      <.xall>
    @DD <.xcref>,    <.xlist>,    <.xmm>
    @DD <alias>,     <align>,     <assume>,     <catstr>
    @DD <comm>,      <comment>,   <db>,         <dd>
    @DD <df>,        <dosseg>,    <dq>,         <dt>
    @DD <dw>,        <echo>,      <else>,       <elseif>
    @DD <elseif1>,   <elseif2>,   <elseifb>,    <elseifdef>
    @DD <elseifdif>, <elseifdifi>,<elseife>,    <elseifidn>
    @DD <elseifidni>,<elseifnb>,  <elseifndef>, <end>
    @DD <endif>,     <endm>,      <endp>,       <ends>
    @DD <equ>,       <even>,      <exitm>,      <extern>
    @DD <externdef>, <extrn>,     <for>,        <forc>
    @DD <goto>,      <group>,     <if>,         <if1>
    @DD <if2>,       <ifb>,       <ifdef>,      <ifdif>
    @DD <ifdifi>,    <ife>,       <ifidn>,      <ifidni>
    @DD <ifnb>,      <ifndef>,    <incbin>,     <include>
    @DD <includelib>,<instr>,     <invoke>,     <irp>
    @DD <irpc>,      <label>,     <local>,      <macro>
    @DD <name>,      <option>,    <org>,        <page>
    @DD <popcontext>,<proc>,      <proto>,      <public>
    @DD <purge>,     <pushcontext>,<record>,    <repeat>
    @DD <rept>,      <segment>,   <sizestr>,    <struc>
    @DD <struct>,    <substr>,    <subtitle>,   <subttl>
    @DD <textequ>,   <title>,     <typedef>,    <union>
    @DD <while>

enddirtab label dword

if OPTR_COLORED
optrtab label dword
    @DD <.type>,     <high>,      <high32>,     <highword>
    @DD <imagerel>,  <length>,    <lengthof>,   <low>
    @DD <low32>,     <lowword>,   <lroffset>,   <mask>
    @DD <offset>,    <opattr>,    <sectionrel>, <seg>
    @DD <short>,     <size>,      <sizeof>,     <this>
    @DD <type>,      <width>
    @DD <eq>,        <ne>,        <ge>,         <gt>
    @DD <le>,        <lt>,        <mod>,        <ptr>
    @DD <dup>
endoptrtab label dword
endif

if TYPE_COLORED
typetab label dword
    @DD <byte>,      <sbyte>,     <word>,       <sword>
    @DD <dword>,     <sdword>,    <real4>,      <fword>
    @DD <qword>,     <sqword>,    <real8>,      <tbyte>
    @DD <real10>,    <oword>,     <ymmword>,    <near>
    @DD <far>,       <near16>,    <near32>,     <far16>
    @DD <far32>,     <mmword>,    <xmmword>
endtypetab label dword
endif

if REGS_COLORED

;--- array of register names which are to be displayed "colored"

regtab label dword

    @DD <ax>,      <bx>,      <cx>,      <dx>
    @DD <bp>,      <sp>,      <si>,      <di>
    @DD <al>,      <bl>,      <cl>,      <dl>
    @DD <ah>,      <bh>,      <ch>,      <dh>
    @DD <eax>,     <ebx>,     <ecx>,     <edx>
    @DD <ebp>,     <esp>,     <esi>,     <edi>
    @DD <cs>,      <ds>,      <es>,      <ss>
    @DD <fs>,      <gs>
    @DD <mm0>,     <mm1>,     <mm2>,     <mm3>
    @DD <mm4>,     <mm5>,     <mm6>,     <mm7>
    @DD <xmm0>,    <xmm1>,    <xmm2>,    <xmm3>
    @DD <xmm4>,    <xmm5>,    <xmm6>,    <xmm7>
    @DD <cr0>,     <cr2>,     <cr3>,     <cr4>
if REGS64
    @DD <rax>,     <rbx>,     <rcx>,     <rdx>
    @DD <rbp>,     <rsp>,     <rsi>,     <rdi>
    @DD <r8>,      <r9>,      <r10>,     <r11>
    @DD <r12>,     <r13>,     <r14>,     <r15>
    @DD <spl>,     <bpl>,     <sil>,     <dil>
    @DD <r8b>,     <r9b>,     <r10b>,    <r11b>
    @DD <r12b>,    <r13b>,    <r14b>,    <r15b>
    @DD <r8w>,     <r9w>,     <r10w>,    <r11w>
    @DD <r12w>,    <r13w>,    <r14w>,    <r15w>
    @DD <r8d>,     <r9d>,     <r10d>,    <r11d>
    @DD <r12d>,    <r13d>,    <r14d>,    <r15d>
    @DD <xmm8>,    <xmm9>,    <xmm10>,   <xmm11>
    @DD <xmm12>,   <xmm13>,   <xmm14>,   <xmm15>
    @DD <cr8>
endif

endregtab label dword

endif

if INST_COLORED

stdinsttab label dword
    @DD <call>, <jmp>
    @DD <ja>,  <jae>,  <jb>,  <jbe>, <jc>, <je>, <jg>, <jge>, <jl>, <jle>
    @DD <jna>, <jnae>, <jnb>, <jnbe>,<jnc>,<jne>,<jng>,<jnge>,<jnl>,<jnle>
    @DD <jo>,  <jp>,   <js>,  <jz>,  <jpe>
    @DD <jno>, <jnp>,  <jns>, <jnz>, <jpo>
    @DD <jcxz>, <jecxz>
    @DD <loop>,  <loope>, <loopz>, <loopne>, <loopnz>
    @DD <loopd>, <looped>,<loopzd>,<loopned>,<loopnzd>
    @DD <loopw>, <loopew>,<loopzw>,<loopnew>,<loopnzw>
    @DD <add>,<or>,<adc>,<sbb>,<and>,<sub>,<xor>,<cmp>
    @DD <rcl>,<rcr>,<rol>,<ror>,<sal>,<sar>,<shl>,<shr>
    @DD <cmps>,<cmpsb>,<cmpsd>,<cmpsw>
    @DD <ins>,<insb>,<insd>,<insw>
    @DD <lods>,<lodsb>,<lodsd>,<lodsw>
    @DD <movs>,<movsb>,<movsd>,<movsw>
    @DD <outs>,<outsb>,<outsd>,<outsw>
    @DD <scas>,<scasb>,<scasd>,<scasw>
    @DD <stos>,<stosb>,<stosd>,<stosw>
    @DD <aaa>,<aad>,<aam>,<aas>
    @DD <daa>,<das>,<lds>,<les>
    @DD <popa>,<popad>,<popaw>,<popfd>
    @DD <pusha>,<pushad>,<pushaw>,<pushfd>
    @DD <pushd>,<retd>,<retw>
    @DD <arpl>,<lldt>,<lsmw>,<ltr>,<sldt>,<smsw>,<str>,<verr>,<verw>
    @DD <div>,<idiv>,<mul>,<neg>,<not>
    @DD <lock>,<rep>,<repe>,<repne>,<repnz>,<repz>
    @DD <bound>,<bsf>,<bsr>,<bswap>,<bt>,<btc>,<btr>,<bts>
    @DD <cbw>,<cdq>,<clc>,<cld>,<cli>,<clts>,<cmc>,<cmpxchg>
    @DD <cmpxchg8b>,<cpuid>,<cwd>,<cwde>,<dec>,<enter>,<hlt>,<imul>
    @DD <in>,<inc>,<int>,<into>,<invlpg>,<iret>,<iretd>,<iretdf>
    @DD <iretf>,<lahf>,<lar>,<lea>,<leave>,<lfs>,<lgdt>,<lgs>
    @DD <lidt>,<lsl>,<lss>,<mov>,<movsx>,<movzx>,<nop>,<out>
    @DD <pop>,<popf>,<push>,<pushw>,<pushf>,<rdmsr>,<rdpmc>,<rdtsc>
    @DD <ret>,<retn>,<retf>,<rsm>,<sahf>,<sgdt>,<shld>,<shrd>
    @DD <sidt>,<stc>,<std>,<sti>,<sysenter>,<sysexit>,<test>,<ud2>
    @DD <wait>,<wbinvd>,<wrmsr>,<xadd>,<xchg>,<xlat>,<xlatb>
    @DD <seta>,<setae>,<setb>,<setbe>,<setc>,<sete>,<setg>
    @DD <setge>,<setl>,<setle>,<setna>,<setnae>,<setnb>,<setnbe>
    @DD <setnc>,<setne>,<setng>,<setnge>,<setnl>,<setnle>,<setno>
    @DD <setnp>,<setns>,<setnz>,<seto>,<setp>,<setpe>,<setpo>,<sets>,<setz>
    @DD <cmova>,  <cmovae>,  <cmovb>,  <cmovbe>, <cmovc>, <cmove>, <cmovg>, <cmovge>, <cmovl>, <cmovle>
    @DD <cmovna>, <cmovnae>, <cmovnb>, <cmovnbe>,<cmovnc>,<cmovne>,<cmovng>,<cmovnge>,<cmovnl>,<cmovnle>
    @DD <cmovo>,  <cmovp>,   <cmovs>,  <cmovz>,  <cmovpe>
    @DD <cmovno>, <cmovnp>,  <cmovns>, <cmovnz>, <cmovpo>
endstdinsttab label dword

fpuinsttab label dword
    @DD <f2xm1>,  <fabs>,   <fadd>,    <faddp>,  <fbld>
    @DD <fbstp>,  <fchs>,   <fclex>,   <fcmovb>, <fcmovbe>
    @DD <fcmove>, <fcmovnb>,<fcmovnbe>,<fcmovne>,<fcmovnu>
    @DD <fcmovu>, <fcom>,   <fcomi>,   <fcomip>, <fcomp>
    @DD <fcompp>, <fcos>,   <fdecstp>, <fdisi>,  <fdiv>
    @DD <fdivp>,  <fdivr>,  <fdivrp>,  <feni>,   <ffree>
    @DD <ffreep>, <fiadd>,  <ficom>,   <ficomp>, <fidiv>
    @DD <fidivr>, <fild>,   <fimul>,   <fincstp>,<finit>
    @DD <fist>,   <fistp>,  <fisub>,   <fisubr>, <fld>
    @DD <fld1>,   <fldcw>,  <fldenv>,  <fldenvd>,<fldenvw>
    @DD <fldl2e>, <fldl2t>, <fldlg2>,  <fldln2>, <fldpi>
    @DD <fldz>,   <fmul>,   <fmulp>,   <fnclex>, <fndisi>
    @DD <fneni>,  <fninit>, <fnop>,    <fnsave>, <fnsaved>
    @DD <fnsavew>,<fnstcw>, <fnstenv>, <fnstenvd>,<fnstenvw>
    @DD <fnstsw>, <fpatan>, <fprem>,   <fprem1>, <fptan>
    @DD <frndint>,<frstor>, <frstord>, <frstorw>,<fsave>
    @DD <fsaved>, <fsavew>, <fscale>,  <fsetpm>, <fsin>
    @DD <fsincos>,<fsqrt>,  <fst>,     <fstcw>,  <fstenv>
    @DD <fstenvd>,<fstenvw>,<fstp>,    <fstsw>,  <fsub>
    @DD <fsubp>,  <fsubr>,  <fsubrp>,  <ftst>,   <fucom>
    @DD <fucomi>, <fucomip>,<fucomp>,  <fucompp>,<fwait>
    @DD <fxam>,   <fxch>,   <fxrstor>, <fxsave>, <fxtract>
    @DD <fyl2x>,  <fyl2xp1>
endfpuinsttab label dword

mmxsseinsttab label dword
;--- todo
endmmxsseinsttab label dword

endif

startstring label byte
    db "<!DOCTYPE HTML PUBLIC ",22h,"-//W3C//DTD HTML 3.2 FINAL//EN",22h,">",EOL
    db "<HTML>",EOL
    db "<HEAD>",EOL
    db "<TITLE>"
    db 0
startstring2 label byte
    db "</TITLE>",EOL
    db "</HEAD>",EOL
    db "<BODY>",EOL
    db "<TABLE BORDER=0 CELLSPACING=4 CELLPADDING=4 WIDTH=",22h,"100%",22h,">",EOL
    db '<TR BGCOLOR="#', @CatStr(!', %BG_COLOR,!'), '"><TD>', EOL
    db "<pre>",EOL
    db 0
endstring label byte
    db "</pre>",EOL
    db "</TD></TR>",EOL
    db "</TABLE>",EOL
    db "</BODY>",EOL
    db "</HTML>",EOL
    db 0

fgcolor label byte
    db '<font color="#'
    db 0

fgcolorrest label byte
    db "</font>"
    db 0

    .CODE

is_valid_id_first_char proc stdcall
    cmp al,'.'
    jz yes
    cmp al,'$'
    jz yes
    cmp al,'?'
    jz yes
    cmp al,'@'
    jz yes
    cmp al,'_'
    jz yes
    cmp al,'A'
    jb no
    cmp al,'Z'
    jbe yes
    cmp al,'a'
    jb no
    cmp al,'z'
    jbe yes
no:
    stc
    ret
yes:
    clc
    ret
    align 4
is_valid_id_first_char endp

is_valid_id_char proc stdcall
    cmp al,'$'
    jz yes
    cmp al,'?'
    jz yes
    cmp al,'@'
    jz yes
    cmp al,'_'
    jz yes
    cmp al,'0'
    jb no
    cmp al,'9'
    jbe yes
    cmp al,'A'
    jb no
    cmp al,'Z'
    jbe yes
    cmp al,'a'
    jb no
    cmp al,'z'
    jbe yes
no:
    stc
    ret
yes:
    clc
    ret
    align 4
is_valid_id_char endp

scanreswords proc stdcall uses esi edi ebx ecx pres:ptr BYTE, tab:ptr BYTE, endtab:ptr BYTE
    mov esi, tab
    mov edi, pres
    .while (esi < endtab )
        lodsd
        push esi
        mov esi, eax
        invoke _stricmp, esi, edi
        and eax, eax
        jz found
        pop esi
    .endw
    clc
    ret
found:
    mov eax, esi
    pop esi
    stc
    ret
    align 4
scanreswords endp

;--- convert masm text found in buffer
;--- 1. put comments in gray fgcolor
;--- 2. write directives in bold.
;--- 3. convert '<', '>' and '&' to '&lt;', '&gt;' and '&amp;'

convertbuffer proc uses ebx esi edi fname:ptr BYTE, buffer:ptr BYTE, size_:DWORD, psize:ptr DWORD

local outb:dword
local startword:dword
local firstdir:byte
local lastchar:byte
local inquotes:byte
local inangles:byte
local incomment:byte
local cnt:word
local startline:dword

    mov eax, size_
    shl eax, 2          ;use size*4 for output buffer size
    invoke malloc, eax
    .if ( eax == 0 )
        invoke printf, CStr(<"out of memory",lf>)
        mov ecx, psize
        xor eax, eax
        mov [ecx], eax
        ret
    .endif
    mov ebx, eax
    mov edi, eax
    mov startline, edi
    mov startword, 0
    mov firstdir, 0
    mov inquotes, 0
    mov inangles, 0
    mov incomment, 0
    mov esi, offset startstring
    .while ( byte ptr [esi] )
        movsb
    .endw
    mov esi, fname
    .while ( byte ptr [esi] )
        movsb
    .endw
    mov esi, offset startstring2
    .while ( byte ptr [esi] )
        movsb
    .endw
    mov esi, buffer
    mov ecx, size_
    .while (ecx)
        lodsb
        .if ( incomment == 0 && inquotes == 0 && inangles == 0 )
            .if ( startword == 0 )
                call is_valid_id_first_char
                jc @F
                .if ( edi > startline )
                   push eax
                   mov al,[edi-1]
                   call is_valid_id_char
                   pop eax
                   jnc @F
                .endif
                mov startword, edi
@@:
            .else
                call is_valid_id_char
                .if (CARRY?)
                    ;end of id found.
                    push eax
                    ;terminate id with a 0
                    mov byte ptr [edi], 0
                    .if ( firstdir == 0 )
                        ;check for directive
                        invoke scanreswords, startword, offset dirtab, offset enddirtab
                        .if (CARRY?)  ;found?
                            mov firstdir,1
                            mov edi, startword
                            push esi
                            mov esi, eax
                            mov ax,"b<"
                            stosw
                            mov al,'>'
                            stosb
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov eax,">b/<"
                            stosd
                            pop esi
                            mov startword, 0
                        .endif
                    .endif
if INST_COLORED
                    mov edx, startword
                    .if ( edx && ( edx == startline || byte ptr [edx-1] != '.' ) )
                        ;check for instruction
                        mov al,[edx]
                        or al,20h
                        .if ( al == 'f')
                            invoke scanreswords, startword, offset fpuinsttab, offset endfpuinsttab
                        .else
                            invoke scanreswords, startword, offset stdinsttab, offset endstdinsttab
                        .endif
                        .if (CARRY?)  ;found?
                            mov edi, startword
                            push esi
                            mov esi, offset fgcolor
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, CStr( @CatStr(!", %INST_COLOR, !" ) )
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, eax
                            mov ax,'>"'
                            stosw
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, offset fgcolorrest
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            pop esi
                            mov startword, 0
                        .endif
                    .endif
endif
if REGS_COLORED
                    .if ( startword )
                        ;check for register names
                        invoke scanreswords, startword, offset regtab, offset endregtab
                        .if (CARRY?)  ;found?
                            mov edi, startword
                            push esi
                            mov esi, offset fgcolor
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, CStr( @CatStr(!", %REGS_COLOR, !" ) )
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, eax
                            mov ax,'>"'
                            stosw
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, offset fgcolorrest
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            pop esi
                            mov startword, 0
                        .endif
                    .endif
endif
if OPTR_COLORED
                    .if ( startword )
                        ;check for operator names
                        invoke scanreswords, startword, offset optrtab, offset endoptrtab
                        .if (CARRY?)  ;found?
                            mov edi, startword
                            push esi
                            mov esi, offset fgcolor
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, CStr( @CatStr(!", %OPTR_COLOR, !" ) )
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, eax
                            mov ax,'>"'
                            stosw
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, offset fgcolorrest
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            pop esi
                            mov startword, 0
                        .endif
                    .endif
endif
if TYPE_COLORED
                    .if ( startword )
                        ;check for operator names
                        invoke scanreswords, startword, offset typetab, offset endtypetab
                        .if (CARRY?)  ;found?
                            mov edi, startword
                            push esi
                            mov esi, offset fgcolor
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, CStr( @CatStr(!", %TYPE_COLOR, !" ) )
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, eax
                            mov ax,'>"'
                            stosw
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            mov esi, offset fgcolorrest
                            .while ( byte ptr [esi] )
                                movsb
                            .endw
                            pop esi
                            mov startword, 0
                        .endif
                    .endif
endif
                    pop eax
                    mov startword, 0
                .endif
            .endif
        .endif
        .if ( al == '<' )
            mov eax, ";tl&"
            stosd
            mov al,'<'
        .elseif ( al == '>' )
            mov eax, ";tg&"
            stosd
            mov al,'>'
        .elseif ( al == '&' )
            mov eax, "pma&"
            stosd
            mov al, ";"
            stosb
            mov al,'&'
        .else
            .if ( incomment && ( al == cr || al == lf ))
            ;.if ( ( al == cr || al == lf ) && incomment != 0 )
                push esi
                mov esi, offset fgcolorrest
                .while ( byte ptr [esi] )
                    movsb
                .endw
                pop esi
            .endif
            stosb
        .endif
        .if ( al == lf || al == cr )
            mov startline, edi
            mov startword, 0
            mov firstdir, 0
            mov inquotes, 0
            mov inangles, 0
            mov incomment, 0
        .elseif ( al == ';' && incomment == 0 )
            .if ( inquotes == 0 && inangles == 0 )
                mov incomment, 1
                push esi
                push eax
                mov esi, offset fgcolor
                .while ( byte ptr [esi] )
                    movsb
                .endw
                mov esi, CStr( @CatStr(!", %COM_COLOR, !" ) )
                .while ( byte ptr [esi] )
                    movsb
                .endw
                mov ax,'>"'
                stosw
                pop eax
                pop esi
            .endif
        .elseif ( al == '<' && incomment == 0 && lastchar != '!' )
            inc inangles
        .elseif ( al == '>' && incomment == 0 && lastchar != '!' && inangles )
            dec inangles
        .elseif ( al == '"' && incomment == 0 && lastchar != '!' )
            .if ( inquotes == al )
                mov inquotes, 0
            .else
                mov inquotes, al
            .endif
        .elseif ( al == "'" && incomment == 0 && lastchar != '!' )
            .if ( inquotes == al )
                mov inquotes, 0
            .else
                mov inquotes, al
            .endif
        .endif
        mov lastchar, al
        dec ecx
    .endw
    mov esi, offset endstring
    .while ( byte ptr [esi] )
        movsb
    .endw
    mov eax, ebx
    sub edi, eax
    mov ecx, psize
    mov [ecx], edi
    ret
    align 4
convertbuffer endp

main proc c argc:dword, argv:ptr

local filename:ptr BYTE
local filesize:dword
local buffer:dword
local outbuf:dword
local outbsize:dword
local fname[260]:byte

    .if ( argc < 2 )
        invoke printf, CStr(<"masm2htm v1.2, Public Domain.",lf>)
        invoke printf, CStr(<"masm2htm is a masm to html converter.",lf>)
        invoke printf, CStr(<"usage: masm2htm input_file [output_file]",lf>)
        mov eax,1
        ret
    .endif
    mov ebx,argv
    mov ebx,[ebx+1*4]
    invoke fopen, ebx, CStr("rb")
    .if ( eax )
        mov filename, ebx

        mov ebx, eax
        invoke fseek, ebx, 0, SEEK_END
        invoke ftell, ebx
        .if ( eax == -1 )
            invoke printf, CStr(<"file %s is invalid",lf>), filename
            invoke fclose, ebx
            mov eax,1
            ret
        .endif
        mov filesize, eax
        invoke fseek, ebx, 0, SEEK_SET

        mov eax, filesize
        inc eax
        invoke malloc, eax
        .if ( eax == 0 ) 
            invoke printf, CStr(<"out of memory",lf>)
            invoke fclose, ebx
            mov eax,1
            ret
        .endif
        mov buffer, eax

        invoke fread, buffer, 1, filesize, ebx
        push eax
        invoke fclose, ebx
        pop eax
        .if ( eax != filesize )
            invoke printf, CStr(<"read error [%u]",lf>), errno
            mov eax,1
            ret
        .endif

        mov edx, buffer
        mov byte ptr [edx+eax],0
        invoke convertbuffer, filename, buffer, filesize, addr outbsize

        push eax
        invoke free, buffer
        pop eax
        .if ( eax )
            mov outbuf, eax
            mov edx, argv
            mov ebx, [edx+1*4]
            .if ( argc == 2 )
                invoke strlen, ebx
                add eax, ebx
                .while (eax != ebx && \
                        byte ptr [eax-1] != ':' && \
                        byte ptr [eax-1] != '\' && \
                        byte ptr [eax-1] != '/')
                    dec eax
                .endw
                lea ebx, fname
                invoke strcpy, ebx, eax
                invoke strcat, ebx, CStr(".txt")
            .else
                mov ebx, argv
                mov ebx, [ebx+2*4]
            .endif
            invoke fopen, ebx, CStr("wb")
            .if ( eax )
                mov ebx, eax
                invoke fwrite, outbuf, 1, outbsize, ebx
                .if ( eax != outbsize )
                    invoke printf, CStr(<"write error [%u]",lf>), errno
                .endif
                invoke fclose, ebx
                invoke printf, CStr(<"Done. %u bytes written",lf>), outbsize
            .else
                invoke printf, CStr(<"open('%s') failed [%u]",lf>), ebx, errno
            .endif
            invoke free, outbuf
        .endif
    .else
        invoke printf, CStr(<"open('%s') failed [%u]",lf>), ebx, errno
    .endif
    xor eax,eax
    ret
    align 4

main endp

    END

