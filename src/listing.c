/****************************************************************************
*
*  This code is Public Domain.
*
*  ========================================================================
*
* Description:  listing support
*
* ListingDirective(): handles directives
*   .[NO|X]LIST, .[NO|X]CREF, .LISTALL,
*   .[NO]LISTIF, .[LF|SF|TF]COND,
*   PAGE, TITLE, SUBTITLE, SUBTTL
* ListMacroDirective(): handles directives
*   .[NO]LISTMACRO, .LISTMACROALL, .[X|L|S]ALL
*
****************************************************************************/

#include <stdarg.h>
#include <ctype.h>

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "reswords.h"
#include "segment.h"
#include "tokenize.h"
#include "macro.h"
#include "fastpass.h"
#include "listing.h"
#include "input.h"
#include "msgtext.h"
#include "expreval.h"
#include "types.h"
#include "omfspec.h"
#include "fixup.h"

#define CODEBYTES 9
//#define OFSSIZE 8
#define PREFFMTSTR "25"
#define SHOWRELOCS 1 /* v2.18: 1=show relocs in code lines */
#define CODELINE2 1 /* v2.18: 1=emit a second line for code lines if first line cannot render all bytes */

#ifdef __UNIX__
#define NLSIZ 1
#define NLSTR "\n"
#else
#define NLSIZ 2
#define NLSTR "\r\n"
#endif

extern int_32  LastCodeBufSize;
#if STACKBASESUPP==0
extern enum special_token basereg[];
#endif

#define DOTSMAX 32
static const char  dots[] = " . . . . . . . . . . . . . . . .";

static const char  szFmtProcStk[] = "  %s %s        %-17s %s %c %04" I32_SPEC "X";

enum list_strings {
#define ltext( index, string ) LS_ ## index,
#include "ltext.h"
#undef ltext
};

static const char * const strings[] = {
#define ltext( index, string ) string ,
#include "ltext.h"
#undef ltext
};

static const char szCount[] = "count";

/* cref definitions */

enum list_queues {
    LQ_MACROS,
    LQ_STRUCTS,
#ifdef DEBUG_OUT
    LQ_UNDEF_TYPES,
#endif
    LQ_RECORDS,
    LQ_TYPEDEFS,
    LQ_SEGS,
    LQ_GRPS,
    LQ_PROCS,
    LQ_LAST
};

enum pr_flags {
    PRF_ADDSEG = 0x01
};

struct print_item {
    short type;
    short flags;
    const short *capitems;
    void (*function)();
};


static const short maccap[] = { LS_TXT_MACROS,  LS_TXT_MACROCAP  ,0 };
static const short strcap[] = { LS_TXT_STRUCTS, LS_TXT_STRUCTCAP, 0 };
//static const short reccap[] = { LS_TXT_RECORDS, LS_TXT_RECORDCAP1, -1, LS_TXT_RECORDCAP2, 0 };
static const short reccap[] = { LS_TXT_RECORDS, LS_TXT_RECORDCAP, 0 };
static const short tdcap[]  = { LS_TXT_TYPEDEFS,LS_TXT_TYPEDEFCAP, 0 };
static const short segcap[] = { LS_TXT_SEGS,    LS_TXT_SEGCAP, 0 };
static const short prccap[] = { LS_TXT_PROCS,   LS_TXT_PROCCAP, 0 };

static void log_macro(   const struct asym * );
static void log_struct(  const struct asym *, const char *name, int_32 );
static void log_record(  const struct asym * );
static void log_typedef( const struct asym * );
static void log_segment( const struct asym *, const struct asym *group );
static void log_group(   const struct asym *, const struct dsym * );
static void log_proc(    const struct asym * );

#ifdef DEBUG_OUT
static uint_32 cntLstWrite;
static uint_32 cntLstPrintf;
#endif

static const struct print_item cr[] = {
    { LQ_MACROS,          0, maccap, log_macro   },
    { LQ_STRUCTS,         0, strcap, log_struct  },
#ifdef DEBUG_OUT
    { LQ_UNDEF_TYPES,     0, strcap, log_struct  },
#endif
    { LQ_RECORDS,         0, reccap, log_record  },
    { LQ_TYPEDEFS,        0, tdcap,  log_typedef },
    { LQ_SEGS,            0, segcap, log_segment },
    { LQ_GRPS,   PRF_ADDSEG, NULL,   log_group   },
    { LQ_PROCS,           0, prccap, log_proc    },
};

struct lstleft {
    struct lstleft *next;
    char buffer[4*8];
    char last;
};

static void LstNL( void )
/***********************/
{
    if( CurrFile[LST] ) {
        fwrite( NLSTR, 1, NLSIZ, CurrFile[LST] );
    }
}

/* write a source line to the listing file
 * global variables used inside:
 *  CurrSource:    the - expanded - source line
 *  CurrSeg:       current segment
 *  GeneratedCode: flag if code is generated
 *  MacroLevel:    macro depth
 *
 * "value":
 * LSTTYPE_EQUATE, LSTTYPE_TMACRO: struct asym
 * LSTTYPE_MACROLINE: line buffer
 * LSTTYPE_CODE: struct code_info ( since v2.18 )
 */

void LstWrite( enum lsttype type, uint_32 oldofs, void *value )
/*************************************************************/
{
    uint_32 newofs;
    struct asym *sym = value; /* LSTTYPE_EQUATE, LSTTYPE_TMACRO */
    int     len;
    int     len2;
    int     idx;
    int     srcfile;
    char    *p1;
    char    *p2;
    char    *pSrcline;
    uint_8  *pv;  /* code buffer ptr */
    struct lstleft *pll;
	struct lstleft ll;
#if FASTPASS
	struct list_item *listitem;
#endif
    //char    buffer2[MAX_LINE_LEN]; /* stores text macro value */

    if ( ModuleInfo.list == FALSE || CurrFile[LST] == NULL || ( ModuleInfo.line_flags & LOF_LISTED ) )
        return;
    if ( ModuleInfo.GeneratedCode && ( ModuleInfo.list_generated_code == FALSE ) )
        return;
    /* v2.19: if first pass listing, don't adjust offsets in later passes */
    if ( Options.first_pass_listing && Parse_Pass > PASS_1 )
        return;
    if ( MacroLevel ) {
        switch ( ModuleInfo.list_macro ) {
        case LM_NOLISTMACRO:
            return;
        case LM_LISTMACRO:
            /* todo: filter certain macro lines */
            break;
        }
    }

#ifdef DEBUG_OUT
    cntLstWrite++;
#endif

    ModuleInfo.line_flags |= LOF_LISTED;

    DebugMsg1(("LstWrite( %u, oldofs=%" I32_SPEC "u ): enter [ GeneratedCode=%u, MacroLevel=%u ]\n", type, oldofs, ModuleInfo.GeneratedCode, MacroLevel ));
    pSrcline = CurrSource;
#if FASTPASS
    /* v2.19: neither source nor comment are needed if pass > 1 */
    if ( UseSavedState ) {
        pSrcline = ""; 
        ModuleInfo.CurrComment = NULL;
    }
#endif

    ll.next = NULL;
    memset( ll.buffer, ' ', sizeof( ll.buffer ) );
    srcfile = get_curr_srcfile();
    p2 = ll.buffer;

    switch ( type ) {
    case LSTTYPE_DATA:
    case LSTTYPE_CODE:
        if ( CurrSeg == NULL ) {
            DebugMsg(("LstWrite: LSTTYPE_CODE/LSTTYPE_DATA with CurrSeg==NULL!\n" ));
            break;
        }

        /* v2.19: use '*' qualifier */
        //p2 += sprintf( p2, (ModuleInfo.Ofssize > USE16 ? "%08" I32_SPEC "X " : "%04" I32_SPEC "X " ), oldofs );
        p2 += sprintf( p2, "%0*" I32_SPEC "X ", ModuleInfo.Ofssize > USE16 ? 8 : 4, oldofs );

        if ( Options.first_pass_listing ) {
            break;
#ifdef DEBUG_OUT
        } else if ( Options.max_passes == 1 ) {
            ; /* write a listing in pass 1 */
#endif
        } else if ( Parse_Pass == PASS_1 ) { /* changed v1.96 */
            break;
        }
        newofs = GetCurrOffset();
        len = ( ModuleInfo.Ofssize > USE16) ? CODEBYTES : CODEBYTES + 2; /* in 16-bit, there's room for 2 more bytes */

        /* e.seginfo->written set to FALSE in SetCurrOffset().
         * used for _BSS segments
         */
        if ( CurrSeg->e.seginfo->CodeBuffer == NULL || CurrSeg->e.seginfo->written == FALSE ) {
            while ( oldofs < newofs && len ) {
                *p2++ = '0';
                *p2++ = '0';
                oldofs++;
                len--;
            }
            break;
        }

        idx = (CurrSeg->e.seginfo->current_loc - CurrSeg->e.seginfo->start_loc) - (newofs - oldofs);
        /* OMF holds just a small buffer for one LEDATA record;
         * if it has been flushed, use LastCodeBufSize.
         * v2.18: if parts of the current instruction are in the old buffer,
         * alloc memory on the stack and merge the old and new part.
         * better approach: don't get the contents from CodeBuffer. For code,
         * the bytes should be contained in struct code_info (codegen.c).
         * For data, let data_item() render the contents.
         */
		if ( Options.output_format == OFORMAT_OMF ) {
			/* v2.11: additional check to make the hack more robust [ test case:  db 800000h dup (0) ] */
			if ( ( idx+LastCodeBufSize ) < 0 )
				break; /* just exit. The code bytes area will remain empty */
			if ( idx < 0 ) {
				DebugMsg1(("LstWrite: copy code from codebuffer to temp stack var. idx=%d\n", idx));
				pv = myalloca( newofs - oldofs  );
				memcpy( pv, &CurrSeg->e.seginfo->CodeBuffer[idx+LastCodeBufSize], 0 - idx );
				memcpy( pv + (0 - idx), &CurrSeg->e.seginfo->CodeBuffer[0], ( newofs - oldofs ) - (0 - idx) );
			} else
				pv = &CurrSeg->e.seginfo->CodeBuffer[idx];
		} else {
			if (idx < 0) idx = 0;
			pv = &CurrSeg->e.seginfo->CodeBuffer[idx];
		}


#if SHOWRELOCS
		/* v2.18: mark relocations in listings for code lines.
		 */
		if ( type == LSTTYPE_CODE && value ) {
			struct code_info *CodeInfo = value;
			int oidx = ( CodeInfo->opnd[0].type != OP_NONE && CodeInfo->opnd[0].InsFixup ) ? 0 : 1;
			DebugMsg1(("LstWrite: opnd[%u].type=0x%" I32_SPEC "X fixup=%p\n", oidx, CodeInfo->opnd[oidx].type, CodeInfo->opnd[oidx].InsFixup));
			while ( oldofs < newofs ) {
				if ( CodeInfo->opnd[oidx].type != OP_NONE &&
					CodeInfo->opnd[oidx].InsFixup &&
					CodeInfo->opnd[oidx].InsFixup->locofs == oldofs ) {
					char cType;
					unsigned char cSize = CodeInfo->opnd[oidx].InsFixup->size;
					enum fixup_types ftype = CodeInfo->opnd[oidx].InsFixup->type;
					if ( (p2 - ll.buffer) >= 28 - (cSize*2+2) ) {
 #if CODELINE2
						/* write to second line if no more space in first */
						ll.next = myalloca( sizeof( struct lstleft ) );
						ll.next->next = NULL;
						*p2 = ' ';
						p2 = ll.next->buffer + ((ModuleInfo.Ofssize > USE16) ? 8 : 4);
						memset( ll.next->buffer, ' ', p2 - ll.next->buffer );
						ll.next->last = NULLC;
 #else
						break;
 #endif
					}
					if ( ftype < FIX_SEG )
						cType = ( ftype & 4 ) ? 'o': 'r';
					else
						switch (ftype) {
						case FIX_SEG: cType = 's';break;
						case FIX_HIBYTE: cType = 'h';break;
 #if COFF_SUPPORT || ELF_SUPPORT
						case FIX_OFF32_IMGREL: cType = 'i';break;
						case FIX_OFF32_SECREL: cType = 's';break;
 #endif
						}
					switch ( cSize ) {
					case 1: p2 += sprintf( p2, " %02X%c", *( uint_8 *)pv, cType ); break;
					case 2: p2 += sprintf( p2, " %04X%c", *(uint_16 *)pv, cType ); break;
					case 4:
						if ( CodeInfo->opnd[oidx].InsFixup->type == FIX_PTR16 )
							p2 += sprintf( p2, " %04Xo %04Xs", *(uint_16 *)pv, *(uint_16 *)(pv+2) );
                        else
							p2 += sprintf( p2, " %08" I32_SPEC "X%c", *(uint_32 *)pv, cType );
						break;
					case 6: p2 += sprintf( p2, " %08" I32_SPEC "Xo %04Xs", *(uint_32 *)pv, *(uint_16 *)(pv+4) ); break;
 #if AMD64_SUPPORT
					case 8: p2 += sprintf( p2, " %016" I64_SPEC "X%c", *(uint_64 *)pv, cType ); break;
 #endif
					}
					pv += cSize;
					oldofs += cSize;
					oidx++;
				} else {
					if ( (p2 - ll.buffer) >= 28-2 ) {
 #if CODELINE2
						/* write to second line if no more space in first */
						ll.next = myalloca( sizeof( struct lstleft ) );
						ll.next->next = NULL;
						*p2 = ' ';
						p2 = ll.next->buffer + ((ModuleInfo.Ofssize > USE16) ? 8+1 : 4+1);
						memset( ll.next->buffer, ' ', p2 - ll.next->buffer );
						ll.next->last = NULLC;
					} else {
						if (oidx && *(p2-1) > 'a')
							*p2++ = ' ';
 #else
						break;
 #endif
					}
					p2 += sprintf( p2, "%02X", *(uint_8 *)pv );
					pv++; oldofs++;
				}
			} /* end while() */
		} else
#endif
			while ( oldofs < newofs && len ) {
				p2 += sprintf( p2, "%02X", *(uint_8 *)pv );
				pv++;
				oldofs++;
				len--;
			}

        break;
    case LSTTYPE_EQUATE:
        /* v2.10: display current offset if equate is an alias for a label in this segment
         * v2.17: todo: explain why this might be useful - the current offset where an equate
         *        is defined should be pretty irrelevant.
         * v2.19: Masm does this as well - actually it ALWAYS displays the current offset.
         */
        if ( sym->segment && sym->segment == &CurrSeg->sym ) {
            /* v2.19: display 4-digit offset in 16-bit */
            //p2 += sprintf( ll.buffer, "%08" I32_SPEC "X", GetCurrOffset() );
            p2 += sprintf( ll.buffer, "%0*" I32_SPEC "X", ModuleInfo.Ofssize > USE16 ? 8 : 4, GetCurrOffset() );
        }
        *p2++ = ' ';
        *p2++ = '=';
        *p2++ = ' ';
#if AMD64_SUPPORT
        if ( sym->value3264 != 0 && ( sym->value3264 != -1 || sym->value >= 0 ) )
            /* v2.13: the addition & shift did not work. */
            //sprintf( &ll.buffer[idx+2], "%-" PREFFMTSTR I64_SPEC "X", (uint_64)sym->value + ( (uint_64)sym->value3264 << 32 ) );
#if defined(LLONG_MAX) || defined(__GNUC__) || defined(__TINYC__)
            p2 += sprintf( p2, "%-" PREFFMTSTR I64_SPEC "X", (uint_64)sym->value3264 * 0x100000000 + sym->uvalue );
#else
            p2 += sprintf( p2, "%-" PREFFMTSTR I64_SPEC "X", (uint_64)sym->value3264 * 0x100000000i64 + sym->uvalue );
#endif
        else
#endif
            p2 += sprintf( p2, "%-" PREFFMTSTR I32_SPEC "X", sym->value );
        break;
    case LSTTYPE_TMACRO:
        ll.buffer[1] = '=';
        //GetLiteralValue( buffer2, sym->string_ptr );
        //strcpy( buffer2, sym->string_ptr );
        for ( p1 = sym->string_ptr, p2 = &ll.buffer[3], pll = &ll; *p1; ) {
            if ( p2 >= &pll->buffer[28] ) {
                struct lstleft *next = myalloca( sizeof( struct lstleft ) );
                if ( p2 != &ll.buffer[28] ) *p2 = 0; /* v2.19: additional line, terminate header */
                pll->next = next;
                pll = next;
                pll->next = NULL;
                /* v2.19: header of multi-line is variable in size */
                //memset( pll->buffer, ' ', sizeof( pll->buffer) );
                memset( pll->buffer, ' ', 3 );
                p2 = &pll->buffer[3];
            }
            *p2++ = *p1++;
        }
        if ( p2 != &ll.buffer[28] ) *p2 = 0; /* v2.19: additional line, terminate header */
        break;
    case LSTTYPE_MACROLINE:
        ll.buffer[1] = '>';
        pSrcline = value;
        break;
    case LSTTYPE_LABEL:
        /* v2.19: use '*' qualifier */
        //p2 += sprintf( ll.buffer, (ModuleInfo.Ofssize > USE16 ? "%08" I32_SPEC "X " : "%04" I32_SPEC "X " ), GetCurrOffset() );
        p2 += sprintf( ll.buffer, "%0*" I32_SPEC "X ", ModuleInfo.Ofssize > USE16 ? 8 : 4, GetCurrOffset() );
        break;
    case LSTTYPE_STRUCT:
        p2 += sprintf( ll.buffer, "%08" I32_SPEC "X ", oldofs );
        /* todo: struct may contain "initialized" members - display the contents!
         * v2.18: struct members will have a non-null value argument.
         * It's not clear what that argument will be. Struct sfield has the
         * ivalue member, but that contains the fields initial value as plain string;
         * it has to be tokenized first. The best approach probably is to let
         * data_item() render what's to be displayed.
         */
        break;
    default: /* LSTTYPE_MACRO */
        /* line without token or comment? */
        if ( Token_Count == 0 && ModuleInfo.CurrComment == NULL && srcfile == ModuleInfo.srcfile ) {
            ll.buffer[0] = NULLC;
            p2++;
        }
        break;
    }

#if FASTPASS
    //if ( Parse_Pass == PASS_1 || UseSavedState == FALSE ) {
    if ( UseSavedState == FALSE ) {
#endif
        if (ll.next == NULL) *p2 = ' ';
        idx = sizeof( ll.buffer );
        if ( ModuleInfo.GeneratedCode )
            ll.buffer[28] = '*';
        if ( MacroLevel ) {
            len = sprintf( &ll.buffer[29], "%u", MacroLevel );
            ll.buffer[29+len] = ' ';
        }
        if ( srcfile != ModuleInfo.srcfile ) {
            ll.buffer[30] = 'C';
        }
        ll.last = NULLC;
#if FASTPASS
    }
#endif
    len = strlen( pSrcline );
    len2 = ( ModuleInfo.CurrComment ? strlen( ModuleInfo.CurrComment ) : 0 );

#if FASTPASS
	if ( StoreState ) {
		if ( ll.buffer[0] == NULLC ) {
			listitem = ListAddItem( ll.buffer );
			DebugMsg1(("LstWrite: ListAddItem(><)=%p\n", listitem ));
		} else {
			char buffer[MAX_LINE_LEN+32];
			sprintf( buffer, "%-32s%s%s", ll.buffer, len ? pSrcline : "", len2 ? ModuleInfo.CurrComment : "" );
			listitem = ListAddItem( buffer );
			DebugMsg1(("LstWrite: ListAddItem(>%s<)=%p\n", buffer, listitem ));
		}
	} else if ( UseSavedState ) {
		listitem = ListGetItem( ModuleInfo.GeneratedCode );
		if ( ll.buffer[0] != NULLC ) {
			if (ll.next == NULL) *p2 = ' ';
			ll.buffer[28] = NULLC;
			ListUpdateItem( listitem, ll.buffer );
			DebugMsg1(("LstWrite: ListUpdateItem(%p, >%s<)\n", listitem, ll.buffer ));
		}
	} else {
#endif
		if ( ll.buffer[0] == NULLC )
			LstNL();
		else {
			LstPrintf( "%-32s%s%s" NLSTR, ll.buffer, len ? pSrcline : "", len2 ? ModuleInfo.CurrComment : "" );
			DebugMsg1(("LstWrite: writing (%u b) >%s%s%s<\n", idx + len + len2 + NLSIZ, ll.buffer, pSrcline, len2 ? ModuleInfo.CurrComment : "" ));
		}
#if FASTPASS
	}
#endif

    /* write optional additional lines */
	for ( pll = ll.next, idx = 0; pll; pll = pll->next, idx++ )
#if FASTPASS
		if ( StoreState ) {
			ListAddSubItem( listitem, pll->buffer );
			DebugMsg1(("LstWrite: ListAddSubItem(>%s<) called\n", pll->buffer ));
		} else if ( UseSavedState ) {
			/* may be a new or an existing item! */
			ListUpdateSubItem( listitem, idx, pll->buffer );
			DebugMsg1(("LstWrite: ListUpdateSubItem(%u, >%s<) called\n", idx, pll->buffer ));
		} else
#endif
		{
			LstPrintf( "%s" NLSTR, pll->buffer );
			DebugMsg1(("LstWrite: additional line >%s<\n", pll->buffer ));
		}
    return;
}

void LstWriteSrcLine( void )
/**************************/
{
    LstWrite( LSTTYPE_MACRO, 0, NULL );
}

/* LstPrintf() - used to
 * - print error msgs into the listing
 * - print structs, macros, records, procs, symbols
 * - print special info ( binary map ) by bin.c
 */

void LstPrintf( const char *format, ... )
/***************************************/
{
    va_list     args;

    if( CurrFile[LST] ) {
#ifdef DEBUG_OUT
        cntLstPrintf++;
#endif
        va_start( args, format );
        vfprintf( CurrFile[LST], format, args );
        va_end( args );
    }
}

static const char *get_seg_align( const struct seg_info *seg, char *buffer )
/**************************************************************************/
{
    switch( seg->alignment ) {
    case 0:    return( strings[LS_BYTE]  );
    case 1:    return( strings[LS_WORD]  );
    case 2:    return( strings[LS_DWORD] );
    case 3:    return( strings[LS_QWORD] );
    case 4:    return( strings[LS_PARA]  );
    case 8:    return( strings[LS_PAGE]  );
    case MAX_SEGALIGNMENT:
               return( strings[LS_ABS]   );
    default:
        sprintf( buffer, "%u", 1 << seg->alignment );
        return( buffer );
    }
}

static const char *get_seg_combine( const struct seg_info *seg )
/**************************************************************/
{
    switch( seg->combine ) {
    case COMB_INVALID:    return( strings[LS_PRIVATE] );
    case COMB_STACK:      return( strings[LS_STACK]   );
    case COMB_ADDOFF:     return( strings[LS_PUBLIC]  );
    /* v2.06: added */
    case COMB_COMMON:     return( strings[LS_COMMON]  );
    }
    return( "?" );
}

static void log_macro( const struct asym *sym )
/*********************************************/
{
    int i = sym->name_size;
    const char *pdots;
    const char *type = (sym->isfunc) ? strings[LS_FUNC] : strings[LS_PROC];

    pdots = ((i >= DOTSMAX) ? "" : dots + i + 1 );
#ifdef DEBUG_OUT
    LstPrintf( "%s %s        %s %5lu" NLSTR, sym->name, pdots ,type, ((struct dsym *)sym)->e.macroinfo->count );
#else
    LstPrintf( "%s %s        %s" NLSTR, sym->name, pdots ,type );
#endif
    return;
}

static const char *SimpleTypeString( enum memtype mem_type )
/**********************************************************/
{
    int size = ( mem_type & MT_SIZE_MASK ) + 1;
    switch ( size ) {
    case 1: return( strings[LS_BYTE] );
    case 2: return( strings[LS_WORD] );
    case 4: return( strings[LS_DWORD] );
    case 6: return( strings[LS_FWORD] );
    case 8: return( strings[LS_QWORD] );
    case 10:return( strings[LS_TBYTE] );
    case 16:return( strings[LS_OWORD] );
    }
    return( "" );
}

/* called by log_struct and log_typedef
 * that is, the symbol is ensured to be a TYPE!
 * argument 'buffer' is either NULL or "very" large ( StringBufferEnd ).
 */

static const char *GetMemtypeString( const struct asym *sym, char *buffer )
/*************************************************************************/
{
    const char *p;
    enum memtype mem_type;

    if ( (sym->mem_type & MT_SPECIAL) == 0 )
        return( SimpleTypeString( sym->mem_type ) );

    /* v2.05: improve display of stack vars */
    mem_type = sym->mem_type;
    if ( sym->state == SYM_STACK && sym->is_ptr )
        mem_type = MT_PTR;

    switch ( mem_type ) {
    case MT_PTR:
#if AMD64_SUPPORT
        if ( sym->Ofssize == USE64 )
            p = strings[LS_NEAR];
        else
#endif
            if ( sym->isfar )
                p = strings[LS_FAR16 + sym->Ofssize];
            else
                p = strings[LS_NEAR16 + sym->Ofssize];

        if ( buffer ) { /* Currently, 'buffer' is only != NULL for typedefs */
            int i;
            char *b2 = buffer;
            /* v2.10: improved pointer TYPEDEF display */
            for ( i = sym->is_ptr; i; i-- ) {
                b2 += sprintf( b2, "%s %s ", p, strings[LS_PTR] );
            }
            /* v2.05: added. */
            if ( sym->state == SYM_TYPE && sym->typekind == TYPE_TYPEDEF ) {
                //strcat( buffer, " ");
                if ( sym->target_type )
                    strcpy( b2, sym->target_type->name );
                else if ( ( sym->ptr_memtype & MT_SPECIAL ) == 0 )
                    strcpy( b2, SimpleTypeString( sym->ptr_memtype ) );
            }
            return( buffer );
        }
        return( p );
    case MT_FAR:
        if ( sym->segment )
            return( strings[LS_LFAR] );
        return( strings[LS_LFAR16 + GetSymOfssize( sym )] );
    case MT_NEAR:
        if ( sym->segment )
            return( strings[LS_LNEAR] );
        return( strings[LS_LNEAR16 + GetSymOfssize( sym )] );
    case MT_TYPE:
        if ( *(sym->type->name) )  /* there are a lot of unnamed types */
            return( sym->type->name );
        /* v2.04: changed */
        //return( strings[LS_PTR] );
        return( GetMemtypeString( sym->type, buffer ) );
    //case MT_ABS: /* v2.07: MT_ABS is obsolete */
    case MT_EMPTY: /* number, via EQU or = directive */
        return( strings[LS_NUMBER] );
#ifdef DEBUG_OUT /* v2.11: obsolete */
    case MT_PROC:
        printf("GetMemtypeString: found mem_type=MT_PROC for sym=%s\n", sym->name );
        break;
#endif
    }
    return("?");
}

static const char *GetLanguage( const struct asym *sym )
/******************************************************/
{
    if ( sym->langtype <= 7 )
        return( strings[sym->langtype + LS_VOID] );
    return( "?" );
}

/* display STRUCTs and UNIONs */

static void log_struct( const struct asym *sym, const char *name, int_32 ofs )
/****************************************************************************/
{
    unsigned      i;
    struct dsym   *dir;
    const char    *pdots;
    struct struct_info *si;
    struct sfield *f;
    static int    prefix = 0;

    dir = (struct dsym *)sym;

    /* filter typedefs and records */
    //if ( dir->sym.typekind != TYPE_STRUCT &&
    //     dir->sym.typekind != TYPE_UNION )
    //    return;

    si = dir->e.structinfo;

    if ( !name )
        name = sym->name;
    i = strlen ( name );
    pdots = (( (i+prefix) >= DOTSMAX) ? "" : dots + i + prefix + 1 );
    for ( i = 0; i < prefix; i++ )
        LstPrintf(" ");
    if ( prefix == 0 )
        if ( dir->e.structinfo->alignment > 1)
            LstPrintf( "%s %s        %8" I32_SPEC "X (%u)", name, pdots, sym->total_size, si->alignment );
        else
            LstPrintf( "%s %s        %8" I32_SPEC "X", name, pdots, sym->total_size );
    else
        LstPrintf( "%s %s        %8" I32_SPEC "X", name, pdots, sym->offset + ofs);
    LstNL();
    prefix += 2;
    for( f = si->head; f; f = f->next ) {
        /* recursion if an embedded struct occurs */
        /* v2.09: field init_dir removed */
        //if ( f->sym->mem_type == MT_TYPE && f->init_dir == NULL ) {
        if ( f->sym.mem_type == MT_TYPE && f->ivalue[0] == NULLC ) {
            log_struct( f->sym.type, f->sym.name, f->sym.offset + ofs );
        } else {
            /* don't list unstructured fields without name */
            /* but do list them if they are structured */
            if (*(f->sym.name) || (f->sym.mem_type == MT_TYPE)) {
                i = f->sym.name_size + prefix;
                pdots = ((i >= DOTSMAX) ? "" : dots + i + 1 );
                for ( i = 0; i < prefix; i++ )
                    LstPrintf(" ");
                LstPrintf( "%s %s        %8" I32_SPEC "X   ", f->sym.name, pdots, f->sym.offset + sym->offset + ofs);
                LstPrintf( "%s", GetMemtypeString( &f->sym, NULL ) );
                if ( f->sym.isarray )
                    LstPrintf( "[%u]",f->sym.total_length );
                LstNL();
            }
        }
    }
    prefix -= 2;
}

static void log_record( const struct asym *sym )
/**********************************************/
{
#if AMD64_SUPPORT
    uint_64         mask;
#else
    uint_32         mask;
#endif
    struct dsym     *dir = (struct dsym *)sym;
    struct struct_info *si = dir->e.structinfo;
    struct sfield   *f;
    int i = sym->name_size;
    const char *pdots;

    pdots = ((i >= DOTSMAX) ? "" : dots + i + 1 );
    for( i = 0,f = si->head; f; f = f->next,i++ );
    LstPrintf( "%s %s      %6" I32_SPEC "X  %7X" NLSTR, sym->name, pdots, sym->total_size*8, i );
    for( f = si->head; f; f = f->next ) {
        i = f->sym.name_size + 2;
        pdots = ((i >= DOTSMAX) ? "" : dots + i + 1 );
        for ( i = f->sym.offset, mask = 0; i < f->sym.offset + f->sym.total_size; i++ )
#if AMD64_SUPPORT
#if defined(LLONG_MAX) || defined(__GNUC__) || defined(__TINYC__)
            mask |= 1ULL << i;
#else
            mask |= 1i64 << i;
#endif
        if ( sym->total_size > 4 )
            LstPrintf( "  %s %s      %6" I32_SPEC "X  %7" I32_SPEC "X  %016" I64_SPEC "X %s", f->sym.name, pdots, f->sym.offset, f->sym.total_size, mask, f->ivalue[0] ? f->ivalue : "?" );
        else
            LstPrintf( "  %s %s      %6" I32_SPEC "X  %7" I32_SPEC "X  %08" I32_SPEC "X %s", f->sym.name, pdots, f->sym.offset, f->sym.total_size, (uint_32)mask, f->ivalue[0] ? f->ivalue : "?" );
#else
            mask |= 1 << i;
        LstPrintf( "  %s %s      %6" I32_SPEC "X  %7" I32_SPEC "X  %08" I32_SPEC "X %s", f->sym.name, pdots, f->sym.offset, f->sym.total_size, mask, f->ivalue[0] ? f->ivalue : "?" );
#endif
        LstNL();
    }
}

/* a typedef is a simple struct with no fields. Size might be 0. */

static void log_typedef( const struct asym *sym )
/***********************************************/
{
    //struct dsym         *dir = (struct dsym *)sym;
    //struct struct_info  *si = dir->e.structinfo;
    char *p;
    int i = sym->name_size;
    const char *pdots;
    //char buffer[256];

    pdots = (( i >= DOTSMAX ) ? "" : dots + i + 1 );
    p = StringBufferEnd;
    *p = NULLC;
    if ( sym->mem_type == MT_PROC && sym->target_type ) { /* typedef proto? */
        strcat( p, strings[LS_PROC] );
        strcat( p, " " );
        if ( *sym->target_type->name ) {  /* the name may be "" */
            strcat( p, sym->target_type->name );
            strcat( p," ");
        }
        /* v2.11: target_type has state SYM_TYPE (since v2.09).
         * This state isn't handled properly by GetSymOfsSize(), which is called by GetMemtypeString(),
         * so get the strings here.
         */
        //strcat( p, GetMemtypeString( sym->target_type, NULL ) );
        strcat( p, strings[( sym->target_type->mem_type == MT_NEAR ? LS_LNEAR16 : LS_LFAR16 ) + sym->Ofssize ] );
        strcat( p," " );
        strcat( p, GetLanguage( sym->target_type ) );
    } else
        p = (char *)GetMemtypeString( sym, p );
    LstPrintf( "%s %s    %8" I32_SPEC "u  %s" NLSTR, sym->name, pdots, sym->total_size, p );
}

/* render listing "Segments and Groups":
 * 1. list the segments that are NOT part of a group.
 * 2. list the groups with their segments.
 */

static void log_segment( const struct asym *sym, const struct asym *group )
/*************************************************************************/
{
    char buffer[32];
    struct seg_info *seg = ((struct dsym *)sym)->e.seginfo;

    DebugMsg(("log_segment(%s, %s): grp=%p\n", sym->name, group ? group->name : "NULL", seg->group ));
    if( seg->group == group ) {
        int i = sym->name_size;
        const char *pdots;
        pdots = (( i >= DOTSMAX ) ? "" : dots + i + 1);
        LstPrintf( "%s %s        ", sym->name, pdots );
        if( seg->Ofssize == USE32 ) {
            //LstPrintf( "32 Bit   %08" I32_SPEC "X ", seg->current_loc );
            LstPrintf( "32 Bit   %08" I32_SPEC "X ", sym->max_offset );
#if AMD64_SUPPORT
        } else if( seg->Ofssize == USE64 ) {
            LstPrintf( "64 Bit   %08" I32_SPEC "X ", sym->max_offset );
#endif
        } else {
            //LstPrintf( "16 Bit   %04" I32_SPEC "X     ", seg->current_loc );
            LstPrintf( "16 Bit   %04" I32_SPEC "X     ", sym->max_offset );
        }
        LstPrintf( "%-7s %-8s", get_seg_align( seg, buffer ), get_seg_combine( seg ) );
        LstPrintf( "'%s'", seg->clsym ? seg->clsym->name : "" );
#if 0
        if ( group != NULL )
            LstPrintf( " %s", group->name );
#endif
        LstNL();
    }
}

static void log_group( const struct asym *grp, const struct dsym *segs )
/**********************************************************************/
{
    unsigned i;
    const char *pdots;
    struct seg_item *curr;

    i = grp->name_size;
    pdots = (( i >= DOTSMAX ) ? "" : dots + i + 1);
    LstPrintf( "%s %s        %s" NLSTR, grp->name, pdots, strings[LS_GROUP] );

    /* the FLAT group has an empty segment list;
     * that's why the standard segment list (segs) must be used then.
     */
    if ( grp == (struct asym *)ModuleInfo.g.flat_grp ) {
        DebugMsg(("log_group: def. flat group (%p), scan all segments\n", ModuleInfo.g.flat_grp ));
        for( ; segs; segs = segs->next ) {
            log_segment( (struct asym *)segs, grp );
        }
    } else {
        DebugMsg(("log_group: group %s (%p)\n", grp->name, grp ));
        for( curr = ((struct dsym *)grp)->e.grpinfo->seglist; curr; curr = curr->next ) {
            log_segment( (struct asym *)curr->seg, grp );
        }
    }
}

static const char *get_proc_type( const struct asym *sym )
/********************************************************/
{
    /* if there's no segment associated with the symbol,
     add the symbol's offset size to the distance */
    switch( sym->mem_type ) {
    case MT_NEAR:
        if ( sym->segment == NULL ) {
            return( strings[LS_NEAR16 + GetSymOfssize( sym )] );
        }
        return( strings[LS_NEAR] );
    case MT_FAR:
        if ( sym->segment == NULL ) {
            return( strings[LS_FAR16 + GetSymOfssize( sym )] );
        }
        return( strings[LS_FAR] );
    }
    return( " " );
}

static const char *get_sym_seg_name( const struct asym *sym )
/***********************************************************/
{
    if( sym->segment ) {
        return( sym->segment->name );
    } else {
        return( strings[LS_NOSEG] );
    }
}

/* list Procedures and Prototypes */

static void log_proc( const struct asym *sym )
/********************************************/
{
    struct dsym *f;
    struct dsym *l;
    const char *p;
    struct dsym *dir = (struct dsym *)sym;
    int i = sym->name_size;
    char Ofssize = GetSymOfssize( sym );
    const char *pdots;

    DebugMsg(("log_proc(%s): enter\n", sym->name ));
    pdots = (( i >= DOTSMAX ) ? "" : dots + i + 1 );
    if ( Ofssize )
        p = "%s %s        P %-6s %08" I32_SPEC "X %-8s ";
    else
        p = "%s %s        P %-6s %04" I32_SPEC "X     %-8s ";
    LstPrintf( p,
              sym->name,
              pdots,
              get_proc_type( sym ),
              sym->offset,
              get_sym_seg_name( sym ));

    /* externals (PROTO) don't have a size. Masm always prints 0000 or 00000000 */
    LstPrintf( "%0*" I32_SPEC "X ", Ofssize > USE16 ? 8 : 4, sym->state == SYM_INTERNAL ? sym->total_size : 0 );

#ifdef DEBUG_OUT
    if ( sym->fwdref )
        LstPrintf( "(F) " );
#endif
    if( sym->ispublic ) {
        LstPrintf( "%-9s", strings[LS_PUBLIC] );
    } else if ( sym->state == SYM_INTERNAL ) {
        LstPrintf( "%-9s", strings[LS_PRIVATE] );
    } else {
        LstPrintf( sym->weak ? "*%-8s " : "%-9s ", strings[LS_EXTERNAL] );
#if DLLIMPORT
        if ( sym->dll )
            LstPrintf( "(%.8s) ", sym->dll->name );
#endif
    }

    LstPrintf( "%s" NLSTR, GetLanguage( sym ) );
    /* for PROTOs, list optional altname */
    if ( sym->state == SYM_EXTERNAL && sym->altname ) {
        struct asym *sym2 = sym->altname;
        LstPrintf( "  ");
        LstPrintf( p,
                  sym2->name,
                  pdots+2,
                  get_proc_type( sym2 ),
                  sym2->offset,
                  get_sym_seg_name( sym2 ));
        LstNL();
    }
    /* for PROCs, list parameters and locals */
    if ( sym->state == SYM_INTERNAL ) {

        /* print the procedure's parameters */
        if ( sym->langtype == LANG_C ||
            sym->langtype == LANG_SYSCALL ||
            sym->langtype == LANG_STDCALL ||
            sym->langtype == LANG_FASTCALL ) {
            int cnt;
            /* position f2 to last param */
            for ( cnt = 0, f = dir->e.procinfo->paralist; f; f = f->nextparam )
                cnt++;
            for ( ; cnt; cnt-- ) {
                int curr;
                for ( curr = 1,f = dir->e.procinfo->paralist; curr < cnt;f = f->nextparam, curr++ );
                i = f->sym.name_size;
                pdots = (( i >= DOTSMAX-2 ) ? "" : dots + i + 1 + 2 );
                /* FASTCALL: parameter may be a text macro (=register name) */
                if ( f->sym.state == SYM_TMACRO )
                    LstPrintf( "  %s %s        %-17s %s", f->sym.name, pdots, GetMemtypeString( &f->sym, NULL ), f->sym.string_ptr );
                else
                    LstPrintf( szFmtProcStk, f->sym.name, pdots,
                            f->sym.is_vararg ? strings[LS_VARARG] : GetMemtypeString( &f->sym, NULL ),
#if STACKBASESUPP
                              GetResWName( dir->e.procinfo->basereg, NULL ),
#else
                              GetResWName( basereg[Ofssize], NULL ),
#endif
                            '+', f->sym.offset );
                LstNL();
            }
        } else {
            for ( f = dir->e.procinfo->paralist; f; f = f->nextparam ) {
                i = f->sym.name_size;
                pdots = (( i >= DOTSMAX-2 ) ? "" : dots + i + 1 + 2 );
                LstPrintf( szFmtProcStk, f->sym.name, pdots, GetMemtypeString( &f->sym, NULL ),
#if STACKBASESUPP
                          GetResWName( dir->e.procinfo->basereg, NULL ),
#else
                          GetResWName( basereg[Ofssize], NULL ),
#endif
                          '+', f->sym.offset );
                LstNL();
            }
        }

        /* print the procedure's locals */
        DebugMsg(("log_proc(%s): print locals\n", sym->name ));
        for ( l = dir->e.procinfo->locallist; l; l = l->nextlocal ) {
            char buffer[32];
            i = l->sym.name_size;
            pdots = (( i >= DOTSMAX-2 ) ? "" : dots + i + 1 + 2);
            if ( l->sym.isarray )
                sprintf( buffer, "%s[%" I32_SPEC "u]", GetMemtypeString(&l->sym, NULL), l->sym.total_length );
            else
                strcpy( buffer, GetMemtypeString( &l->sym, NULL ) );
            LstPrintf( szFmtProcStk, l->sym.name, pdots, buffer,
#if STACKBASESUPP
                      GetResWName( dir->e.procinfo->basereg, NULL ),
                      l->sym.offset >= 0 ? '+' : '-', l->sym.offset >= 0 ? l->sym.offset : - l->sym.offset );
#else
                      GetResWName( basereg[Ofssize], NULL ),
                      '-', - l->sym.offset );
#endif
            LstNL();
        }

        for ( l = dir->e.procinfo->labellist; l ; l = l->e.nextll ) {
            struct dsym *l2;
            for ( l2 = l; l2; l2 = (struct dsym *)l2->sym.nextitem ) {
                /* filter params and locals! */
                if ( l2->sym.state == SYM_STACK || l2->sym.state == SYM_TMACRO )
                    continue;
                i = l2->sym.name_size;
                pdots = (( i >= DOTSMAX-2 ) ? "" : dots + i + 1 + 2);
                if ( Ofssize )
                    p = "  %s %s        L %-6s %08" I32_SPEC "X %s";
                else
                    p = "  %s %s        L %-6s %04" I32_SPEC "X     %s";
                LstPrintf( p,
                          l2->sym.name,
                          pdots,
                          get_proc_type( &l2->sym ),
                          l2->sym.offset,
                          get_sym_seg_name( &l2->sym ));
#ifdef DEBUG_OUT
                if ( l2->sym.fwdref )
                    LstPrintf( " (F)" );
#endif
                LstNL();
            }
        }
    }
}

/* list symbols */

static void log_symbol( const struct asym *sym )
/**********************************************/
{
    int i = sym->name_size;
    const char *pdots;
    //char buffer[MAX_LINE_LEN];

    pdots = ((i >= DOTSMAX) ? "" : dots + i + 1 );

    switch ( sym->state ) {
    case SYM_UNDEFINED:
    case SYM_INTERNAL:
    case SYM_EXTERNAL:
        LstPrintf( "%s %s        ", sym->name, pdots );

        if ( sym->isarray ) {
            i = sprintf( StringBufferEnd, "%s[%u]", GetMemtypeString( sym, NULL ), sym->total_length );
            LstPrintf( "%-10s ", StringBufferEnd );
        } else if ( sym->state == SYM_EXTERNAL && sym->iscomm == TRUE ) {
            LstPrintf( "%-10s ", strings[LS_COMM] );
        } else
            LstPrintf( "%-10s ", GetMemtypeString( sym, NULL ) );

        /* print value */
        /* v2.07: MT_ABS is obsolete */
        //if ( sym->mem_type == MT_ABS )
        if ( sym->state == SYM_EXTERNAL && sym->iscomm == TRUE )
            LstPrintf( " %8" I32_SPEC "Xh ", sym->total_size / sym->total_length );
        else if ( sym->mem_type == MT_EMPTY ) { /* also check segment? might be != NULL for equates (var = offset x) */
            if ( sym->value3264 != 0 && sym->value3264 != -1 )
                LstPrintf( " %" I64_SPEC "Xh ", sym->uvalue, sym->value3264 );
            else if ( sym->value3264 < 0 )
                LstPrintf( "-%08" I32_SPEC "Xh ", 0 - sym->uvalue );
            else
                LstPrintf( " %8" I32_SPEC "Xh ", sym->offset );
        } else
            LstPrintf( " %8" I32_SPEC "Xh ", sym->offset );

        /* print segment */
        //if ( sym->mem_type == MT_ABS || sym->state == SYM_UNDEFINED )
        //    ;
        //else
        if ( sym->segment )
            LstPrintf( "%s ", get_sym_seg_name( sym ) );

#ifdef DEBUG_OUT
        if ( sym->fwdref )
            LstPrintf( "(F) " );
        /* list unused global variables if they have a size and aren't public */
        if ( sym->state == SYM_INTERNAL && (!sym->used) && !(sym->mem_type & MT_ADDRESS) && !sym->ispublic )
            LstPrintf( "(U) " );
#endif
        if ( sym->state == SYM_EXTERNAL && sym->iscomm == TRUE )
            LstPrintf( "%s=%u ", szCount, sym->total_length );

        if( sym->ispublic )
            LstPrintf( "%s ", strings[LS_PUBLIC] );

        if ( sym->state == SYM_EXTERNAL ) {
            LstPrintf( sym->weak ? "*%s " : "%s ", strings[LS_EXTERNAL] );
        } else if ( sym->state == SYM_UNDEFINED ) {
            LstPrintf( "%s ", strings[LS_UNDEFINED] );
        }

        LstPrintf( "%s" NLSTR, GetLanguage( sym ) );
        break;
    case SYM_TMACRO:
        //GetLiteralValue( buffer, sym->string_ptr );
        //strcpy( buffer, sym->string_ptr );
        LstPrintf( "%s %s        %s   %s" NLSTR, sym->name, pdots, strings[LS_TEXT], sym->string_ptr );
        break;
    case SYM_ALIAS:
        LstPrintf( "%s %s        %s  %s" NLSTR, sym->name, pdots, strings[LS_ALIAS], sym->substitute->name );
        break;
    }
}

static void LstCaption( const char *caption, int prefNL )
/*******************************************************/
{
    for (; prefNL; prefNL--)
        LstNL();
    LstPrintf( caption );
    LstNL();
    LstNL();
}

static int compare_syms( const void *p1, const void *p2 )
/*******************************************************/
{
    return( strcmp( (*(struct asym * *)p1)->name, (*(struct asym * *)p2)->name ) );
}

/* write symbol table listing */

void LstWriteCRef( void )
/***********************/
{
    struct asym     **syms;
    struct dsym     *dir;
    struct struct_info *si;
    int             idx;
    uint_32         i;
    uint_32         SymCount;
    struct qdesc    queues[LQ_LAST];

    /* no point going through the motions if lst file isn't open */
    if( CurrFile[LST] == NULL || Options.no_symbol_listing == TRUE ) {
        return;
    }

    /* go to EOF */
    fseek( CurrFile[LST], 0, SEEK_END );

    SymCount = SymGetCount();
    syms = MemAlloc( SymCount * sizeof( struct asym * ) );
    SymGetAll( syms );

    DebugMsg(("LstWriteCRef: calling qsort\n"));
    /* sort 'em */
    qsort( syms, SymCount, sizeof( struct asym * ), compare_syms );

    memset( queues, 0, sizeof( queues ) );
    for( i = 0; i < SymCount; ++i ) {
        struct qdesc *q;
        if ( syms[i]->list == FALSE )
            continue;
        switch (syms[i]->state) {
        case SYM_TYPE:
            si = ((struct dsym *)syms[i])->e.structinfo;
            switch ( syms[i]->typekind ) {
            case TYPE_RECORD:  idx = LQ_RECORDS; break;
            case TYPE_TYPEDEF: idx = LQ_TYPEDEFS;break;
            case TYPE_STRUCT:
            case TYPE_UNION:   idx = LQ_STRUCTS ;break;
#ifdef DEBUG_OUT
            default:           idx = LQ_UNDEF_TYPES ;break;
#else
            default: continue; /* skip "undefined" types */
#endif
            }
            break;
        case SYM_MACRO:
            idx = LQ_MACROS;
            break;
        case SYM_SEG:
            idx = LQ_SEGS;
            break;
        case SYM_GRP:
            idx = LQ_GRPS;
            break;
        case SYM_INTERNAL:
        case SYM_EXTERNAL: /* v2.04: added, since PROTOs are now externals */
            if ( syms[i]->isproc ) {
                idx = LQ_PROCS;
                break;
            }
            /* no break */
        default:
            continue;
        }
        q = &queues[idx];
        if( q->head == NULL ) {
            q->head = syms[i];
        } else {
            ((struct dsym *)q->tail)->next = (struct dsym *)syms[i];
        }
        q->tail = syms[i];
        ((struct dsym *)syms[i])->next = NULL;
    }

    /* write macros, structs, records, typedefs, segments & groups, procedures */

    for ( idx = 0; idx < ( sizeof( cr ) / sizeof(cr[0] ) ); idx++ ) {
        if ( queues[cr[idx].type].head ) {
            if ( cr[idx].capitems ) {
                const short *ps;
                for ( ps = cr[idx].capitems; *ps; ps++ ) {
                    //if ( *ps == -1 )
                    //    LstNL();
                    //else
                        LstCaption( strings[ *ps ], ps == cr[idx].capitems ? 2 : 0 );
                }
            }
            for( dir = queues[cr[idx].type].head; dir ; dir = dir->next ) {
                cr[idx].function( &dir->sym, ( cr[idx].flags & PRF_ADDSEG ) ? queues[LQ_SEGS].head : NULL, 0 );
            }
        }
    }

    /* write out symbols */
    LstCaption( strings[ LS_TXT_SYMBOLS ], 2 );
    LstCaption( strings[ LS_TXT_SYMCAP ], 0 );
    for( i = 0; i < SymCount; ++i ) {
        if ( syms[i]->list == TRUE && syms[i]->isproc == FALSE ) {
            DebugMsg(("LstWriteCRef: log_symbol( %s )\n", syms[i]->name ));
            log_symbol( syms[i] );
        }
#ifdef DEBUG_OUT
        else
            DebugMsg(("LstWriteCRef: %s suppressed\n", syms[i]->name ));
#endif
    }
    LstNL();

    /* free the sorted symbols */
    DebugMsg(("LstWriteCRef: free sorted symbols\n"));
    MemFree( syms );
}

/* .[NO|X]LIST, .[NO|X]CREF, .LISTALL, 
 * .[NO]LISTIF, .[LF|SF|TF]COND,
 * PAGE, TITLE, SUBTITLE, SUBTTL directives
 */
ret_code ListingDirective( int i, struct asm_tok tokenarray[] )
/*************************************************************/
{
    int directive = tokenarray[i].tokval;
    int j;
    struct expr opndx;

    i++;

    switch ( directive ) {
    case T_DOT_LIST:
        if ( CurrFile[LST] )
            ModuleInfo.list = TRUE;
        break;
    case T_DOT_CREF:
        ModuleInfo.cref = TRUE;
        break;
    case T_DOT_NOLIST:
    case T_DOT_XLIST:
        ModuleInfo.list = FALSE;
        break;
    case T_DOT_NOCREF:
    case T_DOT_XCREF:
        if ( i == Token_Count ) {
            ModuleInfo.cref = FALSE;
            break;
        }
        do {
            struct asym *sym;
            if ( tokenarray[i].token != T_ID ) {
                return( EmitErr( SYNTAX_ERROR_EX, tokenarray[i].tokpos ) );
            }
            /* the name may be a forward reference. In this case it will
             * be created here.
             * v2.11: function call cannot fail. no need for checks.
             */
            sym = SymLookup( tokenarray[i].string_ptr );
            sym->list = FALSE;
            i++;
            if ( i < Token_Count ) {
                if ( tokenarray[i].token != T_COMMA )
                    return( EmitErr( EXPECTING_COMMA, tokenarray[i].tokpos ) );

                /* if there's nothing after the comma, don't increment */
                if ( i < ( Token_Count - 1 ) )
                    i++;
            }
        } while ( i < Token_Count );
        break;
    case T_DOT_LISTALL: /* list false conditionals and generated code */
        if ( CurrFile[LST] )
            ModuleInfo.list = TRUE;
        ModuleInfo.list_generated_code = TRUE;
        /* fall through */
    case T_DOT_LISTIF:
    case T_DOT_LFCOND: /* .LFCOND is synonym for .LISTIF */
        ModuleInfo.listif = TRUE;
        break;
    case T_DOT_NOLISTIF:
    case T_DOT_SFCOND: /* .SFCOND is synonym for .NOLISTIF */
        ModuleInfo.listif = FALSE;
        break;
    case T_DOT_TFCOND: /* .TFCOND toggles .LFCOND, .SFCOND */
        ModuleInfo.listif = !ModuleInfo.listif;
        break;
    case T_PAGE:
        /* v2.19: optional 1 or 2 numeric arguments; they aren't used currently.
         *        first must be >= 14, <= 255 ( not checked yet )
         *        second must be >= 60, <= 255 ( not checked yet )
         */
        j = i;
        if ( ( ERROR == EvalOperand( &i, tokenarray, Token_Count, &opndx, 0 ) ) )
            return( ERROR );
        if ( opndx.kind != EXPR_CONST && opndx.kind != EXPR_EMPTY )  /* first arg may be omitted */
            return( EmitErr( SYNTAX_ERROR_EX, tokenarray[j].tokpos ) );
        if ( tokenarray[i].token == T_COMMA ) {
            i++;
            j = i;
            if ( ( ERROR == EvalOperand( &i, tokenarray, Token_Count, &opndx, 0 ) ) )
                return( ERROR );
            if ( opndx.kind != EXPR_CONST )
                return( EmitErr( SYNTAX_ERROR_EX, tokenarray[j].tokpos ) );
        }
        break;
    default: /* TITLE, SUBTITLE, SUBTTL */
        /* tiny checks to ensure that these directives
         aren't used as code labels or struct fields */
        if ( tokenarray[i].token == T_COLON )
            break;
        /* this isn't really Masm-compatible, but ensures we don't get
         * struct fields with names page, title, subtitle, subttl.
         */
        if( CurrStruct ) {
            return( EmitError( STATEMENT_NOT_ALLOWED_INSIDE_STRUCTURE_DEFINITION ) );
        }
        if ( Parse_Pass == PASS_1 )
            EmitWarn( 4, DIRECTIVE_IGNORED, tokenarray[i-1].string_ptr );
        while ( tokenarray[i].token != T_FINAL) i++;
    }

    if ( tokenarray[i].token != T_FINAL ) {
        return( EmitErr( SYNTAX_ERROR_EX, tokenarray[i].string_ptr ) );
    }

    return( NOT_ERROR );
}

/* directives .[NO]LISTMACRO, .LISTMACROALL, .[X|L|S]ALL */

ret_code ListMacroDirective( int i, struct asm_tok tokenarray[] )
/***************************************************************/
{
    if ( tokenarray[i+1].token != T_FINAL ) {
        return( EmitErr( SYNTAX_ERROR_EX, tokenarray[i+1].string_ptr ) );
    }

    ModuleInfo.list_macro = GetSflagsSp( tokenarray[i].tokval );

    return( NOT_ERROR );
}

/* LstInit() - called for each pass */

void LstInit( void )
/******************/
{
    //const struct fname_item *fn;

    if ( Parse_Pass == PASS_1 ) {
#ifdef DEBUG_OUT
        cntLstWrite  = 0;
        cntLstPrintf = 0;
#endif
    } else {
        if ( CurrFile[LST]
#if FASTPASS
         && UseSavedState == FALSE
#endif
           ) {
            rewind( CurrFile[LST] );
        } else
            return;
    }
    if( Options.write_listing ) {
        LstPrintf("%s" NLSTR, MsgGetEx( MSG_JWASM ) );
        //fn = GetFName( ModuleInfo.srcfile );
        LstPrintf("%s" NLSTR, GetFName( ModuleInfo.srcfile )->fname );
    }
}
#ifdef DEBUG_OUT
void LstFini( void )
/******************/
{
    if ( Options.write_listing && Options.quiet == FALSE )
        printf("calls LstWrite/LstPrintf=%" I32_SPEC "u/%" I32_SPEC "u\n", cntLstWrite, cntLstPrintf );
}
#endif
