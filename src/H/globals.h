/****************************************************************************
*
*                            Open Watcom Project
*
*    Portions Copyright (c) 1983-2002 Sybase, Inc. All Rights Reserved.
*
*  ========================================================================
*
*    This file contains Original Code and/or Modifications of Original
*    Code as defined in and that are subject to the Sybase Open Watcom
*    Public License version 1.0 (the 'License'). You may not use this file
*    except in compliance with the License. BY USING THIS FILE YOU AGREE TO
*    ALL TERMS AND CONDITIONS OF THE LICENSE. A copy of the License is
*    provided with the Original Code and Modifications, and is also
*    available at www.sybase.com/developer/opensource.
*
*    The Original Code and all software distributed under the License are
*    distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
*    EXPRESS OR IMPLIED, AND SYBASE AND ALL CONTRIBUTORS HEREBY DISCLAIM
*    ALL SUCH WARRANTIES, INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF
*    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR
*    NON-INFRINGEMENT. Please see the License for the specific language
*    governing rights and limitations under the License.
*
*  ========================================================================
*
* Description:  JWasm globals and limits.
*
****************************************************************************/


#ifndef _GLOBALS_H_INCLUDED
#define _GLOBALS_H_INCLUDED

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h> /* needed for errno declaration ( "sometimes" it's defined in stdlib.h ) */

#if defined(__UNIX__) || defined(__CYGWIN__) || defined(__DJGPP__) /* avoid for MinGW! */

#define _stricmp strcasecmp
#ifndef __WATCOMC__
#define _memicmp strncasecmp
#endif
#define _ltoa   ltoa
#define _strupr strupr
char *strupr(char *);

#elif defined(__POCC__)

#pragma warn(disable:2030) /* disable '=' used in a conditional expression */
#pragma warn(disable:2229) /* disable 'local x is potentially used without ...' */
#pragma warn(disable:2231) /* disable 'enum value x not handled in switch statement' */

#elif defined(__BORLANDC__) || defined(__OCC__)

#define _stricmp  stricmp
#define _strnicmp strnicmp
#define _strupr   strupr
#define _memicmp  memicmp

#endif

#define MAX_LINE_LEN            600  /* no restriction for this number */
#define MAX_TOKEN  MAX_LINE_LEN / 4  /* max tokens in one line */
#define MAX_STRING_LEN          MAX_LINE_LEN - 32 /* must be < MAX_LINE_LEN */
#define MAX_ID_LEN              247  /* must be < MAX_LINE_LEN */
#define MAX_STRUCT_ALIGN        32
/* v2.06: obsolete */
//#define MAX_RESW_LEN            31 /* max length of a reserved word */

#define MAX_IF_NESTING          20 /* IFxx block nesting. Must be <=32, see condasm.c */
//#define MAX_TEXTMACRO_NESTING   20
#define MAX_SEG_NESTING         20 /* limit for segment nesting  */
#ifdef __I86__
#define MAX_MACRO_NESTING       20
#else
#define MAX_MACRO_NESTING       40 /* macro call nesting  */
#endif
#define MAX_STRUCT_NESTING      32 /* limit for "anonymous structs" only */

#define MAX_LNAME              255 /* OMF lnames - length must fit in 1 byte */
#define LNAME_NULL             0   /* OMF first entry in lnames array */

/* output format switches */
#ifndef BIN_SUPPORT
#define BIN_SUPPORT  1 /* support BIN output format              */
#endif
#if BIN_SUPPORT
#ifndef MZ_SUPPORT
#define MZ_SUPPORT   1 /* support DOS MZ binary format           */
#endif
#ifndef PE_SUPPORT
#define PE_SUPPORT   1 /* support PE32 + PE64 binary format      */
#endif
#else
#define MZ_SUPPORT 0 /* both MZ and PE need BIN==1 */
#define PE_SUPPORT 0
#endif

#ifndef COFF_SUPPORT
#define COFF_SUPPORT 1 /* support COFF output format             */
#endif
#ifndef DJGPP_SUPPORT
#define DJGPP_SUPPORT 0 /* support for Djgpp COFF variant        */
#endif
#ifndef ELF_SUPPORT
#define ELF_SUPPORT  1 /* support ELF output format              */
#endif

/* instruction set switches */
#define K3DSUPP      1 /* support K3D instruction set            */
#define SSE3SUPP     1 /* support SSE3 instruction set           */
#ifndef AMD64_SUPPORT
#define AMD64_SUPPORT 1 /* 1=support 64bit */
#endif
#ifndef VMXSUPP
#define VMXSUPP      1 /* support VMX extensions                 */
#endif
#ifndef SVMSUPP
#define SVMSUPP      0 /* support SVM (=AMD-V) extensions        */
#endif
#ifndef SSSE3SUPP
#define SSSE3SUPP    1 /* support SSSE3 instruction set          */
#endif
#ifndef SSE4SUPP
#define SSE4SUPP     1 /* support SSE4 instruction set           */
#endif
#ifndef AVXSUPP
#define AVXSUPP      1 /* support AVX extensions                 */
#endif
#ifndef COMDATSUPP
#define COMDATSUPP   1 /* support COMDAT segment attribute       */
#endif

/* other extension switches */
#define IMAGERELSUPP 1 /* support IMAGEREL operator (not for OMF) */
#define SECTIONRELSUPP 1 /* support SECTIONREL operator (not for OMF) */
#define FIELDALIGN   1 /* support OPTION FIELDALIGN:<const>      */
#define PROCALIGN    1 /* support OPTION PROCALIGN:<const>       */
#define LOHI32       1 /* support LOW32/HIGH32 operators         */
#define XMMWORD      1 /* support MMWORD and XMMWORD types       */
#define RENAMEKEY    1 /* support OPTION RENAMEKEYWORD:<old>,new */
#define MACROLABEL   1 /* support LABEL qualifier for macro arg  */
#define BACKQUOTES   1 /* allow IDs enclosed in `                */
#define FPIMMEDIATE  1 /* allow float immediates: mov eax,1.0    */
#define INCBINSUPP   1 /* support INCBIN directive               */
#define INTELMOVQ    0 /* 1=MOVQ moves to/from 64-bit registers  */
#ifndef OWFC_SUPPORT
#define OWFC_SUPPORT 1 /* support OW fastcall flavor             */
#endif
#ifndef DLLIMPORT
#define DLLIMPORT    1 /* support OPTION DLLIMPORT               */
#endif
#ifndef CVOSUPP
#define CVOSUPP      1 /* support OPTION CODEVIEW                */
#endif
#define MASM_SSE_MEMX 1 /* support 2 mem types for mmx/xmm       */
#define PERCENT_OUT 1  /* 1=support %OUT directive               */
#ifndef STACKBASESUPP
#define STACKBASESUPP 1 /* support OPTION STACKBASE              */
#endif
#define VARARGML 1    /* multi line vararg for macros */

/* old Wasm extensions */
#define PAGE4K       0 /* support 4kB-page OMF segment alignment */
#define BUILD_TARGET 0 /* support "build target" (obsolete)   */
#define COCTALS      0 /* allow C form of octals              */
#define CHEXPREFIX   0 /* accept "0x" as hex number prefix    */
#define MANGLERSUPP  0 /* support Wasm's "mangler" extension  */

/* internal assembler optimizations */
#ifndef FASTPASS
#define FASTPASS     1 /* don't scan full source if pass > 1  */
#endif
#ifndef FASTMEM
#define FASTMEM      1 /* fast memory allocation              */
#endif

#include "inttype.h"
#include "bool.h"
#include "errmsg.h"  /* must be located AFTER #defines lines */
#include "queue.h"

/* JWasm version info */
#define _JWASM_VERSION_STR_ "2.17"
#define _JWASM_VERSION_INT_ 217
#define _JWASM_VERSION_SUFFIX_ ""
#define _JWASM_VERSION_ _JWASM_VERSION_STR_ _JWASM_VERSION_SUFFIX_

#define NULLC  '\0'
//#define NULLS  ""

#define is_valid_id_char( ch )  ( isalnum(ch) || ch=='_' || ch=='@' || ch=='$' || ch=='?' )
#define is_valid_id_first_char( ch )  ( isalpha(ch) || ch=='_' || ch=='@' || ch=='$' || ch=='?' || (ch == '.' && ModuleInfo.dotname == TRUE ))

/* function return values */

typedef enum {
 EMPTY = -2,
 ERROR = -1,
 NOT_ERROR = 0,
 STRING_EXPANDED = 1
} ret_code;

enum {
    PASS_1 = 0,
    PASS_2
};

/* enumerations */

/* output formats. Order must match formatoptions[] in assemble.c */
enum oformat {
#if BIN_SUPPORT
    OFORMAT_BIN, /* used by -bin, -mz and -pe */
#endif
    OFORMAT_OMF,
#if COFF_SUPPORT
    OFORMAT_COFF,/* used by -coff, -djgpp and -win64 */
#endif
#if ELF_SUPPORT
    OFORMAT_ELF, /* used by -elf and elf64 */
#endif
};

enum sformat {
    SFORMAT_NONE,
#if MZ_SUPPORT
    SFORMAT_MZ,    /* MZ binary */
#endif
#if PE_SUPPORT
    SFORMAT_PE,    /* PE (32- or 64-bit) binary */
#endif
#if COFF_SUPPORT
 #if DJGPP_SUPPORT
    SFORMAT_DJGPP, /* Djgpp variant of COFF */
 #endif
#endif
#if COFF_SUPPORT || ELF_SUPPORT
 #if AMD64_SUPPORT
    SFORMAT_64BIT, /* 64bit COFF or ELF */
 #endif
#endif
};

enum fpo {
    FPO_NO_EMULATION,  /* -FPi87 (default) */
    FPO_EMULATION      /* -FPi */
};

/* language vaules.
 * the order cannot be changed, it's
 * returned by OPATTR and used in user-defined prologue/epilogue.
 */
enum lang_type {
    LANG_NONE     = 0,
    LANG_C        = 1,
    LANG_SYSCALL  = 2,
    LANG_STDCALL  = 3,
    LANG_PASCAL   = 4,
    LANG_FORTRAN  = 5,
    LANG_BASIC    = 6,
    LANG_FASTCALL = 7
};

/* Memory model type.
 * the order cannot be changed, it's
 * the value of the predefined @Model symbol.
 */
enum model_type {
    MODEL_NONE    = 0,
    MODEL_TINY    = 1,
    MODEL_SMALL   = 2,
    MODEL_COMPACT = 3,
    MODEL_MEDIUM  = 4,
    MODEL_LARGE   = 5,
    MODEL_HUGE    = 6,
    MODEL_FLAT    = 7,
};

#define SIZE_DATAPTR 0x68 /* far for COMPACT, LARGE, HUGE */
#define SIZE_CODEPTR 0x70 /* far for MEDIUM, LARGE, HUGE  */

enum seg_order {
    SEGORDER_SEQ = 0,  /* .SEQ (default) */
    SEGORDER_DOSSEG,   /* .DOSSEG */
    SEGORDER_ALPHA     /* .ALPHA */
};

/* .NOLISTMACRO, .LISTMACRO and .LISTMACROALL directives setting */
enum listmacro {
    LM_NOLISTMACRO,
    LM_LISTMACRO,
    LM_LISTMACROALL
};

/* assume values are used as index in codegen.c / invoke.c.
 * Order must match the one in special.h. Don't change!
 */
enum assume_segreg {
    ASSUME_NOTHING = EMPTY,
    ASSUME_ES = 0,
    ASSUME_CS,
    ASSUME_SS,
    ASSUME_DS,
    ASSUME_FS,
    ASSUME_GS
};

enum cpu_info {
    /* bit count from left:
     * bit 0-2:   Math coprocessor
     * bit 3:     privileged?
     * bit 4-7:   cpu type
     * bit 8-15;  extension set
     */
    P_NO87  = 0x0001,         /* no FPU */
    P_87    = 0x0002,         /* 8087 */
    P_287   = 0x0003,         /* 80287 */
    P_387   = 0x0004,         /* 80387 */

    P_PM    = 0x0008,         /* privileged opcode */

    P_86    = 0x0000,         /* 8086, default */
    P_186   = 0x0010,         /* 80186 */
    P_286   = 0x0020,         /* 80286 */
    P_386   = 0x0030,         /* 80386 */
    P_486   = 0x0040,         /* 80486 */
    P_586   = 0x0050,         /* pentium */
    P_686   = 0x0060,         /* ppro */
#if AMD64_SUPPORT
    P_64    = 0x0070,         /* x64 cpu */
#endif

    P_286p  = P_286 | P_PM,   /* 286, priv mode */
    P_386p  = P_386 | P_PM,   /* 386, priv mode */
    P_486p  = P_486 | P_PM,   /* 486, priv mode */
    P_586p  = P_586 | P_PM,   /* 586, priv mode */
    P_686p  = P_686 | P_PM,   /* 686, priv mode */
#if AMD64_SUPPORT
    P_64p   = P_64 | P_PM,    /* x64, priv mode */
#endif

    P_MMX   = 0x0100,         /* MMX extension instructions */
#if K3DSUPP
    P_K3D   = 0x0200,         /* 3DNow extension instructions */
#endif
    P_SSE1  = 0x0400,         /* SSE1 extension instructions */
    P_SSE2  = 0x0800,         /* SSE2 extension instructions */
    P_SSE3  = 0x1000,         /* SSE3 extension instructions */
#if SSSE3SUPP
    P_SSSE3 = 0x2000,         /* SSSE3 extension instructions */
#if SSE4SUPP
    P_SSE4  = 0x4000,         /* SSE4 extension instructions */
#if AVXSUPP
    P_AVX   = 0x8000,         /* AVX extension instructions */
#endif
#endif
#endif
    /* all SSE extension instructions */
#if SSSE3SUPP
 #if SSE4SUPP
  #if AVXSUPP
    P_SSEALL = P_SSE1 | P_SSE2 | P_SSE3 | P_SSSE3 | P_SSE4 | P_AVX,
  #else
    P_SSEALL = P_SSE1 | P_SSE2 | P_SSE3 | P_SSSE3 | P_SSE4,
  #endif
 #else
    P_SSEALL = P_SSE1 | P_SSE2 | P_SSE3 | P_SSSE3,
 #endif
#else
    P_SSEALL = P_SSE1 | P_SSE2 | P_SSE3,
#endif
    NO_OPPRFX = P_MMX | P_SSEALL,

    P_FPU_MASK = 0x0007,
    P_CPU_MASK = 0x00F0,

#if K3DSUPP
    P_EXT_MASK = P_MMX | P_K3D | P_SSEALL,
    P_EXT_ALL  = P_MMX | P_K3D | P_SSEALL
#else
    P_EXT_MASK = P_MMX | P_SSEALL,
    P_EXT_ALL  = P_MMX | P_SSEALL
#endif
};

/* the MASM compatible @CPU value flags: */
enum masm_cpu {
    M_8086 = 0x0001, /* 8086 */
    M_186  = 0x0002, /* 186 */
    M_286  = 0x0004, /* 286 */
    M_386  = 0x0008, /* 386 */
    M_486  = 0x0010, /* 486 */
    M_586  = 0x0020, /* Pentium */
    M_686  = 0x0040, /* PPro */
    M_CPUMSK = 0x007F,
    M_PROT = 0x0080, /* protected instructions ok */
    M_8087 = 0x0100, /* 8087 */
    M_287  = 0x0400, /* 287 */
    M_387  = 0x0800  /* 387 */
};

#if MANGLERSUPP
enum naming_types {
    NC_DO_NOTHING,
    /*  put uscores on the front of labels & the back of procedures.
     * this is what the OW compiler does with /3r
     */
    NC_ADD_USCORES,
    /* assume that the user manually put uscores as described above
     * into the assembly file and take them off
     */
    NC_REMOVE_USCORES
};
#endif

enum segofssize {
    USE_EMPTY = 0xFE,
    USE16 = 0, /* don't change values of USE16,USE32,USE64! */
    USE32 = 1,
#if AMD64_SUPPORT
    USE64 = 2
#endif
};

/* fastcall types. if order is to be changed or entries
 * added, also adjust tables in proc.c, mangle.c and probably invoke.c!
 */
enum fastcall_type {
    FCT_MSC,        /* MS 16-/32-bit fastcall (ax,dx,cx / ecx,edx) */
#if OWFC_SUPPORT
    FCT_WATCOMC,    /* OW register calling convention (eax, ebx, ecx, edx) */
#endif
#if AMD64_SUPPORT
    FCT_WIN64       /* Win64 fastcall convention (rcx, rdx, r8, r9) */
#endif
};

enum stdcall_decoration {
    STDCALL_FULL,
    STDCALL_NONE,
    STDCALL_HALF
};

struct qitem {
    void *next;
    char value[1];
};

/* file extensions. Order must match first entries in enum opt_names! */
enum file_extensions {
    ASM, /* must be first; see SetFilenames() in assembly.c */
    OBJ,
    LST,
    ERR,
    NUM_FILE_TYPES
};

/* first 4 entries must match enum file_extensions! */
enum opt_names {
    OPTN_ASM_FN,
    OPTN_OBJ_FN,              /* -Fo option */
    OPTN_LST_FN,              /* -Fl option */
    OPTN_ERR_FN,              /* -Fr option */
#if DLLIMPORT
    OPTN_LNKDEF_FN,           /* -Fd option */
#endif
    OPTN_MODULE_NAME,         /* -nm option */
    OPTN_TEXT_SEG,            /* -nt option */
    OPTN_DATA_SEG,            /* -nd option */
    OPTN_CODE_CLASS,          /* -nc option */
#if BUILD_TARGET
    OPTN_BUILD_TARGET,        /* -bt option */
#endif
#if MANGLERSUPP
    OPTN_DEFNAME_MANGLER,
#endif
    OPTN_LAST
};

/* queues to store multiple cmdline switch values */
enum opt_queues {
    OPTQ_FINCLUDE, /* -Fi option values */
    OPTQ_MACRO,    /* -D option values */
    OPTQ_INCPATH,  /* -I option values */
    OPTQ_LAST
};

enum prologue_epilogue_mode {
    PEM_DEFAULT, /* must be value 0 */
    PEM_MACRO,
    PEM_NONE
};

/* Stack distance */
enum dist_type {
    //STACK_NONE,
    STACK_NEAR,
    STACK_FAR,
};

/* Type of operating system */
enum os_type {
    OPSYS_DOS,
    OPSYS_OS2,
};

enum offset_type {
    OT_GROUP = 0,  /* OFFSET:GROUP (default, must be 0) */
    OT_FLAT,       /* OFFSET:FLAT    */
    OT_SEGMENT     /* OFFSET:SEGMENT */
};

enum line_output_flags {
    LOF_LISTED = 1, /* line written to .LST file */
#if FASTPASS
    LOF_SKIPPOS  = 2, /* suppress setting list_pos */
    //LOF_STORED = 2  /* line stored in line buffer for FASTPASS */
#endif
};

/* flags for win64_flags */
enum win64_flag_values {
    W64F_SAVEREGPARAMS = 0x01, /* 1=save register params in shadow space on proc entry */
    W64F_AUTOSTACKSP   = 0x02, /* 1=calculate required stack space for arguments of INVOKE */
    W64F_STACKALIGN16  = 0x04, /* 1=stack variables are 16-byte aligned; added in v2.12 */
    W64F_ALL = W64F_SAVEREGPARAMS | W64F_AUTOSTACKSP | W64F_STACKALIGN16, /* all valid flags */
};

/* codeview debug info extend */
enum cvex_values {
    CVEX_MIN     = 0, /* globals */
    CVEX_REDUCED = 1, /* globals and locals */
    CVEX_NORMAL  = 2, /* globals, locals and types */
    CVEX_MAX     = 3, /* globals, locals, types and constants */
};

/* codeview debug info option flags */
enum cvoption_flags {
    CVO_STATICTLS = 1, /* handle static tls */
};

enum seg_type {
    SEGTYPE_UNDEF,
    SEGTYPE_CODE,
    SEGTYPE_DATA,
    SEGTYPE_BSS,
    SEGTYPE_STACK,
    SEGTYPE_ABS,
#if PE_SUPPORT
    SEGTYPE_HDR,   /* only used in bin.c for better sorting */
    SEGTYPE_CDATA, /* only used in bin.c for better sorting */
    SEGTYPE_RELOC, /* only used in bin.c for better sorting */
    SEGTYPE_RSRC,  /* only used in bin.c for better sorting */
    SEGTYPE_ERROR, /* must be last - an "impossible" segment type */
#endif
};

struct global_options {
    bool        quiet;                 /* -q option */
    bool        line_numbers;          /* -Zd option */
    uint_8      debug_symbols;         /* -Zi option */
    uint_8      debug_ext;             /* -Zi option numeric argument */
    enum fpo    floating_point;        /* -FPi, -FPi87 */

    /* error handling stuff */
    int         error_limit;             /* -e option  */
    uint_8      no_error_disp;           /* -eq option */
    uint_8      warning_level;           /* -Wn option */
    bool        warning_error;           /* -WX option */
#ifdef DEBUG_OUT
    bool        debug;                   /* -dt option */
    bool        nobackpatch;             /* -nbp option */
#if FASTPASS
    bool        nofastpass;              /* -nfp option */
    bool        print_linestore;         /* -ls option */
#endif
    uint_16     max_passes;              /* -pm option */
    bool        skip_preprocessor;       /* -sp option */
    bool        log_all_files;           /* -af option */
    bool        dump_reswords;           /* -dr option */
    bool        dump_reswords_hash;      /* -drh option */
    bool        dump_symbols;            /* -ds option */
    bool        dump_symbols_hash;       /* -dsh option */
#endif
    char        *names[OPTN_LAST];
    struct qitem *queues[OPTQ_LAST];
#if COCTALS
    bool        allow_c_octals;          /* -o option */
#endif
    bool        no_comment_data_in_code_records; /* -zlc option */
    bool        no_opt_farcall;          /* -zld option */
//    bool        no_dependencies;         /* -zld option */
#if COFF_SUPPORT
    bool        no_file_entry;           /* -zlf option */
    bool        no_static_procs;         /* -zlp option */
    bool        no_section_aux_entry;    /* -zls option  */
#endif
    bool        no_cdecl_decoration;     /* -zcw & -zcm option */
    uint_8      stdcall_decoration;      /* -zt<0|1|2> option */
    bool        no_export_decoration;    /* -zze option */
    bool        entry_decorated;         /* -zzs option  */
    bool        write_listing;           /* -Fl option  */
    bool        write_impdef;            /* -Fd option  */
    bool        case_sensitive;          /* -C<p|x|u> options */
    bool        convert_uppercase;       /* -C<p|x|u> options */
    bool        preprocessor_stdout;     /* -EP option  */
    bool        masm51_compat;           /* -Zm option  */
    bool        strict_masm_compat;      /* -Zne option  */
    bool        masm_compat_gencode;     /* -Zg option  */
    bool        masm8_proc_visibility;   /* -Zv8 option  */
    bool        listif;                  /* -Sx, -Sa option  */
    bool        list_generated_code;     /* -Sg, -Sa option  */
    enum listmacro list_macro;           /* -Sa option  */
    bool        no_symbol_listing;       /* -Sn option  */
    bool        first_pass_listing;      /* -Sf option  */
    bool        no_final_msg_listing;    /* -Sz option (v2.13) */
    bool        all_symbols_public;      /* -Zf option  */
    bool        safeseh;                 /* -safeseh option */
    uint_8      ignore_include;          /* -X option */
    enum oformat output_format;          /* -bin, -omf, -coff, -elf options */
    enum sformat sub_format;             /* -mz, -pe, -win64, -elf64 options */
    uint_8      fieldalign;              /* -Zp option  */
    enum lang_type langtype;             /* -Gc|d|z option */
    enum model_type model;               /* -mt|s|m|c|l|h|f option */
    enum cpu_info cpu;                   /* -0|1|2|3|4|5|6 & -fp{0|2|3|5|6|c} option */
    enum fastcall_type fctype;           /* -zf0 & -zf1 option */
    bool        syntax_check_only;       /* -Zs option */
#if MANGLERSUPP
    enum naming_types naming_convention; /* OW naming peculiarities */
#endif
};

#if MZ_SUPPORT
/* if the structure changes, option.c, SetMZ() might need adjustment! */
struct MZDATA {
    uint_16 ofs_fixups; /* offset start fixups */
    uint_16 alignment; /* header alignment: 16,32,64,128,256,512 */
    uint_16 heapmin;
    uint_16 heapmax;
};
#endif

#if DLLIMPORT
struct dll_desc {
    struct dll_desc *next;
    int cnt;     /* a function of this dll was used by INVOKE */
    char name[1];
};
#endif

/* Information about the module */

struct src_item;
struct hll_item;
struct context;

struct fname_item {
    char    *fname;
    //char    *fullname; /* v2.11: removed */
    //time_t  mtime; /* v2.11: removed */
#ifdef DEBUG_OUT
    unsigned included;
    uint_32  lines;
#endif
};

struct module_info;

struct module_vars {
    unsigned            error_count;     /* total of errors so far */
    unsigned            warning_count;   /* total of warnings so far */
    unsigned            num_segs;        /* number of segments in module */
    /* v2.07: GlobalQueue is obsolete */
    //struct qdesc        GlobalQueue;     /* GLOBAL items ( =externdefs ) */
    struct qdesc        PubQueue;        /* PUBLIC items */
    struct qdesc        LnameQueue;      /* LNAME items (segments, groups and classes) */
#if COFF_SUPPORT
    struct qdesc        SafeSEHQueue;    /* list of safeseh handlers */
#endif
    struct qdesc        LibQueue;        /* includelibs */
    /* v2.11: AltQueue is obsolete */
    //struct symbol_queue AltQueue;        /* weak externals */
    //struct qdesc        AltQueue;        /* weak externals */
#if DLLIMPORT
    struct dll_desc     *DllQueue;       /* dlls of OPTION DLLIMPORT */
#endif
#if PE_SUPPORT || DLLIMPORT
    char                *imp_prefix;
#endif
    FILE                *curr_file[NUM_FILE_TYPES];  /* ASM, ERR, OBJ and LST */
    char                *curr_fname[NUM_FILE_TYPES];
    struct fname_item   *FNames;         /* array of input files */
    unsigned            cnt_fnames;      /* items in FNames array */
    char                *IncludePath;
    struct qdesc        line_queue;      /* line queue */
    struct src_item     *src_stack;      /* source item (files & macros) stack */
    union {
        struct fixup    *start_fixup;    /* OMF only */
        struct asym     *start_label;    /* non-OMF only: start label */
    };
    uint_32             start_displ;     /* OMF only, optional displ for start label */
    struct hll_item     *HllStack;       /* for .WHILE, .IF, .REPEAT */
    struct hll_item     *HllFree;        /* v2.06: stack of free <struct hll>-items */
    struct context      *ContextStack;
    struct context      *ContextFree;    /* v2.10: "free items" heap implemented. */
#if FASTPASS
    struct context      *SavedContexts;
    int                 cntSavedContexts;
#endif
    /* v2.10: moved here from module_info due to problems if @@: occured on the very first line */
    unsigned            anonymous_label; /* "anonymous label" counter */
#if STACKBASESUPP
    struct asym         *StackBase;
    struct asym         *ProcStatus;
#endif
    ret_code (* WriteModule)( struct module_info * );
    ret_code (* EndDirHook)( struct module_info * );
    ret_code (* Pass1Checks)( struct module_info * );
#if PE_SUPPORT
    uint_8              pe_flags;        /* for PE */
#endif
};

struct format_options;

struct module_info {
    struct module_vars  g;
    char                *proc_prologue;  /* prologue macro if PEM_MACRO */
    char                *proc_epilogue;  /* epilogue macro if PEM_MACRO */
#if DLLIMPORT
    struct dll_desc     *CurrDll;        /* OPTION DLLIMPORT dll */
#endif
    const struct format_options *fmtopt; /* v2.07: added */
    unsigned            hll_label;       /* hll directive label counter */
    enum dist_type      distance;        /* stack distance */
    enum model_type     model;           /* memory model */
    enum lang_type      langtype;        /* language */
    enum os_type        ostype;          /* operating system */
    enum sformat        sub_format;      /* sub-output format */
    enum fastcall_type  fctype;          /* fastcall type */
    enum seg_order      segorder;        /* .alpha, .seq, .dosseg */
    enum offset_type    offsettype;      /* OFFSET:GROUP|FLAT|SEGMENT */
    short               cpu;             /* cpu setting (value @cpu symbol); */
    enum cpu_info       curr_cpu;        /* cpu setting (OW stylex); */
    unsigned char       radix;           /* current .RADIX setting */
    unsigned char       fieldalign;      /* -Zp, OPTION:FIELDALIGN setting */
    unsigned char       line_flags;      /* current line has been printed */
#if PROCALIGN
    unsigned char       procalign;       /* current OPTION:PROCALIGN setting */
#endif
    enum listmacro      list_macro;      /* current .LISTMACRO setting */
    unsigned char       Ofssize;         /* current offset size (USE16,USE32,USE64) */
    unsigned char       defOfssize;      /* default segment offset size (16,32 [,64]-bit) */
    unsigned char       wordsize;        /* current word size (2,4,8) */
    unsigned char       inside_comment;  /* v2.10: moved from tokenize.c */

    unsigned            case_sensitive:1;     /* option casemap */
    unsigned            convert_uppercase:1;  /* option casemap */
    unsigned            procs_private:1; /* option proc:private */
    unsigned            procs_export:1;  /* option proc:export */
    unsigned            dotname:1;       /* option dotname */
    unsigned            ljmp:1;          /* option ljmp */
    unsigned            m510:1;          /* option m510 */
    unsigned            scoped:1;        /* option scoped */
    unsigned            oldstructs:1;    /* option oldstructs */
    unsigned            emulator:1;      /* option emulator */
    unsigned            setif2:1;        /* option setif2 */
    unsigned            list:1;          /* .list/.nolist */
    unsigned            cref:1;          /* .cref/.nocref */
    unsigned            listif:1;        /* .listif/.nolistif */
    unsigned            list_generated_code:1; /* .listall, -Sa, -Sg */
    unsigned            StartupDirectiveFound:1;
    unsigned            EndDirFound:1;
#if AMD64_SUPPORT
    unsigned            frame_auto:1;    /* win64 only */
#endif
    unsigned            NoSignExtend:1;  /* option nosignextend */
#if ELF_SUPPORT || AMD64_SUPPORT || MZ_SUPPORT
    union {
#if ELF_SUPPORT || AMD64_SUPPORT
        struct {
#if ELF_SUPPORT
        uint_8          elf_osabi;       /* for ELF */
#endif
#if AMD64_SUPPORT
        uint_8          win64_flags;     /* for WIN64 + PE(32+) */
#endif
        };
#endif
#if MZ_SUPPORT
        struct MZDATA   mz_data;         /* for MZ */
#endif
    };
#endif
    unsigned char       simseg_init;     /* simplified segm dir flags */
    unsigned char       simseg_defd;     /* v2.09: flag if seg was defined before simseg dir */
    unsigned char       PhaseError;      /* phase error flag */
    unsigned char       CommentDataInCode;/* OMF: emit coment records about data in code segs */
    unsigned char       prologuemode;    /* current PEM_ enum value for OPTION PROLOGUE */
    unsigned char       epiloguemode;    /* current PEM_ enum value for OPTION EPILOGUE */
    unsigned char       invoke_exprparm; /* flag: forward refs for INVOKE params ok? */
#if CVOSUPP
    unsigned char       cv_opt;          /* option codeview */
#endif
    unsigned            srcfile;         /* main source file - is an index for FNames[] */
    struct dsym         *currseg;        /* currently active segment */
    struct dsym         *flat_grp;       /* magic FLAT group */
    uint_8              *pCodeBuff;
    unsigned int        GeneratedCode;   /* nesting level generated code */
    /* input members */
    char                *currsource;     /* current source line */
    char                *CurrComment;    /* current comment */
    struct asm_tok      *tokenarray;     /* start token buffer */
    char                *stringbufferend;/* start free space in string buffer */
    int                 token_count;     /* number of tokens in curr line */
#if STACKBASESUPP
    unsigned            basereg[3];      /* stack base register (16-, 32-, 64-bit */
#endif
    char                name[FILENAME_MAX];/* name of module */
};

#define CurrSource      ModuleInfo.currsource
#define Token_Count     ModuleInfo.token_count
#define StringBufferEnd ModuleInfo.stringbufferend
#define CurrFile        ModuleInfo.g.curr_file
#define CurrFName       ModuleInfo.g.curr_fname
#define CurrSeg         ModuleInfo.currseg
#define CurrWordSize    ModuleInfo.wordsize

struct format_options {
    void (*init)( struct module_info * );
    short invalid_fixup_type;
    const char formatname[6];
};

/* global variables */

extern struct global_options Options;
extern struct module_info    ModuleInfo;
extern unsigned int          Parse_Pass;    /* assembly pass */
//extern unsigned int          GeneratedCode;  /* v2.10: moved to struct module_info */
extern uint_8                MacroLevel;    /* macro nesting level */
extern bool                  write_to_file; /* 1=write the object module */

/* Information about source, object, listing and error files */
//extern FILE                  *CurrFile[];   /* ASM, ERR, OBJ and LST */
//extern char                  *CurrFName[];  /* ASM, ERR, OBJ and LST */

/* functions in assemble.c */

struct fixup;

extern void             OutputByte( unsigned char );
//extern void             OutputCodeByte( unsigned char );
extern void             FillDataBytes( unsigned char, int len );
extern void             OutputBytes( const unsigned char *, int len, struct fixup * );
#ifdef __SW_BD
extern int  __stdcall   AssembleModule( const char * );
#else
extern int              AssembleModule( const char * );
#endif
extern void             AddLinnumDataRef( unsigned, uint_32 );
extern void             SetMasm510( bool );
extern void             close_files( void );
extern char             *myltoa( uint_32 value, char *buffer, unsigned radix, bool sign, bool addzero );
#if COFF_SUPPORT || PE_SUPPORT
extern char             *ConvertSectionName( const struct asym *, enum seg_type *pst, char *buffer );
#endif

#endif
