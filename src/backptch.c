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
* Description:  backpatch: short forward jump optimization.
*
****************************************************************************/
#ifndef DEBUG_OUT
//#define DEBUG_OUT
#endif

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "fixup.h"
#include "segment.h"

/*
 * LABELOPT: short jump label optimization.
 * if this is 0, there is just the simple "fixup backpatch",
 * which cannot adjust any label offsets between the forward reference
 * and the newly defined label, resulting in more passes to be needed.
 * v2.21: turned out that this implementation isn't fool-proved (see vcovl.asm).
 *        hence it's now deactivated; backpatching will need a redesign!
 *        with "LABELOPT 0", regression test bin/jmpfwd2.asm FAILS!
*/
#define LABELOPT 1

/* DoPatch:
 * v2.19: DoPatch() is now generally called in pass one only;
 * - sym: current label
 * - fixup: forward reference
 */

static void DoPatch( struct asym *sym, struct fixup *fixup )
/**********************************************************/
{
    int_32              disp;
    unsigned            size;
    struct dsym         *seg;
#if LABELOPT
    struct asym         *sym2;
    struct fixup        *fixup2;
#endif

    DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): fixup type=%u ofs=%" I32_SPEC "Xh loc=%" I32_SPEC "Xh opt=%u def_seg=%s\n",
              sym->name, sym->offset,
              fixup->type,
              fixup->offset,
              fixup->locofs,
              fixup->option,
              fixup->def_seg ? fixup->def_seg->sym.name : "NULL" ));

    seg = GetSegm( sym );
    if( seg == NULL || fixup->def_seg != seg ) {
        /* if fixup location is in another segment, backpatch is possible, but
         * not implemented since calculation of new size is non-trivial.
         */
        DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): segs differ: %s - %s\n", sym->name, sym->offset,
                  fixup->def_seg ? fixup->def_seg->sym.name : "NULL",
                  seg ? seg->sym.name : "NULL" ));
        return;
    }

    switch( fixup->type ) {
    case FIX_RELOFF32:
    case FIX_RELOFF16:
        if( sym->mem_type == MT_FAR && fixup->option == OPTJ_CALL ) {
            /* convert near call to push cs + near call,
             * (only at first pass) */
            DebugMsg(("DoPatch(%s, %" I32_SPEC "X): Phase error! caused by far call optimization\n", sym->name, sym->offset));
            ModuleInfo.PhaseError = TRUE;
            sym->offset++;  /* a PUSH CS will be added */
            /* todo: insert LABELOPT block here */
            OutputByte( 0 ); /* it's pass one, nothing is written */
            return;
        }
        DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): FIX_RELOFF32/FIX_RELOFF16, skipped\n", sym->name, sym->offset));
        return;
    case FIX_OFF8:  /* push <forward reference> */
        if ( fixup->option == OPTJ_PUSH ) {
            /* how to check value? */
            DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): FIX_OFF8 for PUSH\n", sym->name, sym->offset));
            break;
        }
        return;
    case FIX_RELOFF8:
        /* calculate the displacement */
        // disp = fixup->offset + GetCurrOffset() - fixup->location - size;
        disp = fixup->offset + fixup->sym->offset - ( fixup->locofs + 1 );
        if ( disp > 127 || disp < -128 ) {
            DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): loc=%" I32_SPEC "X - out of range, disp=%d [fixup=%s,%X]\n",
                 sym->name, sym->offset, fixup->locofs, disp, fixup->sym->name, fixup->sym->offset ));
            break;
        }
        //DebugMsg1(("DoPatch, loc=%" I32_SPEC "X: displacement unchanged: %d\n", fixup->locofs, disp ));
        return;
    default:
        DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): unhandled fixup type=%u\n", sym->name, sym->offset, fixup->type ));
        return;
    }

    switch( fixup->option ) {
    case OPTJ_EXPLICIT:
#if 0 /* don't display the error at the destination line! */
        DebugMsg(("DoPatch: jump out of range, disp=%d\n", disp ));
        EmitErr( JUMP_OUT_OF_RANGE, disp - 127 );
#endif
        return;
    case OPTJ_EXTEND: /* Jxx for 8086 */
        size = 3;     /* 3 (no 32-bit possible) */
        break;
    case OPTJ_JXX:    /* Jxx for 386 */
        size = 2;     /* 2/4 */
        break;
    //case OPTJ_JMPS: /* short JMP */
    //case OPTJ_CALL: /* can't happen */
    //case OPTJ_PUSH: /* push BYTE */
    default:
        size = 1;     /* 1/3 */
        break;
    }

    if( seg->e.seginfo->Ofssize )
        size += 2; /* JMP: NEAR16/NEAR32; PUSH: WORD/DWORD */

#if LABELOPT
    /* v2.04: if there's an ORG between src and dst, skip
     * the optimization!
     */
    for ( fixup2 = seg->e.seginfo->FixupList.head; fixup2; fixup2 = fixup2->nextrlc ) {
        if ( fixup2->orgoccured ) {
            DebugMsg(("DoPatch(%s %" I32_SPEC "X): ORG/ALIGN detected, optimization canceled\n", sym->name, sym->offset ));
            return;
        }
        /* do this check after the check for ORG! */
        if ( fixup2->locofs <= fixup->locofs )
            break;
    }

    ModuleInfo.PhaseError = TRUE;

    /* scan the segment's label list and adjust all labels
     * that are between the fixup loc and the current sym.
     * ( PROCs are NOT contained in this list because they
     * use the <next>-field of dsym already!)
     */
    for ( sym2 = seg->e.seginfo->label_list; sym2; sym2 = (struct asym *)((struct dsym *)sym2)->next ) {
        //if ( sym2 == sym )
        //    continue;
        /* v2.0: location is at least 1 byte too low, so
         * use the "<=" operator instead of "<"!
         */
        //if ( sym2->offset < fixup->locofs )
        if ( sym2->offset <= fixup->locofs )
            break;
        sym2->offset += size;
        DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): loc=%" I32_SPEC "X, sym %s, offset %" I32_SPEC "X -> %" I32_SPEC "X\n", sym->name, sym->offset,
                   fixup->locofs, sym2->name, sym2->offset - size, sym2->offset));
    }
    /* v2.03: also adjust fixup locations located between the
     * label reference and the label. This should reduce the
     * number of passes to 2 for not too complex sources.
     */
    for ( fixup2 = seg->e.seginfo->FixupList.head; fixup2 && fixup2->locofs > fixup->locofs; fixup2 = fixup2->nextrlc ) {
        if ( fixup2->sym == sym ) {
            DebugMsg1(("DoPatch(%s, %" I32_SPEC "X):     sym=%s fixup loc %" I32_SPEC "X\n", sym->name, sym->offset,
                       fixup2->sym->name, fixup2->locofs ));
            fixup2->option = OPTJ_NONE;
        } else if ( fixup2->option != OPTJ_NONE ) {
            fixup2->locofs += size;
            DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): for sym=%s fixup loc %" I32_SPEC "X -> %" I32_SPEC "X\n", sym->name, sym->offset,
                       fixup2->sym->name, fixup2->locofs - size, fixup2->locofs ));
        }
    }
#else
    DebugMsg1(("DoPatch(%s, %" I32_SPEC "X): offset changed to %" I32_SPEC "X\n", sym->name, sym->offset, sym->offset + size));
    sym->offset += size;
#endif
    /* adjust $; in pass one it doesn't matter what's actually "written" */
    for ( ; size; size-- )
        OutputByte( 0xCC );
    return;
}

ret_code BackPatch( struct asym *sym )
/************************************/
/*
 * patching for forward reference labels in Jmp/Call instructions;
 * called by
 * - LabelCreate() [label.c]
 * - ProcDef()     [proc.c]
 * - data_dir()    [data.c]
 * - SetValue()    [equate.c]
 * that is, whenever a (new) label is defined. The new label is the
 * <sym> argument. During the process, the label's offset might be changed!
 *
 * field sym->bp_fixup is a "descending" list of forward references
 * to this symbol. These fixups are only generated during pass 1.
 */
{
	if ( Parse_Pass == PASS_1 ) {
		struct fixup     *fixup;
#if 0 /* activate if symbols that aren't forward referenced shouldn't appear in log */
		if ( sym->bp_fixup )
#endif
		DebugMsg1(("BackPatch(%s, %s:%" I32_SPEC "X): bp_fixup=%p\n", sym->name, sym->segment ? sym->segment->name : "!NULL!", sym->offset, sym->bp_fixup ));
		for( fixup = sym->bp_fixup; fixup; fixup = fixup->nextbp )
			/* v2.21: skip non-backpatch fixups */
			if ( fixup->option != OPTJ_NONE ) /* a jmp/jxx/call/push instruction? */
				DoPatch( sym, fixup );
	}
    return( NOT_ERROR );
}

