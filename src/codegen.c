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
* Description:  instruction encoding, scans opcode table and emits code.
*
****************************************************************************/

#include <limits.h>

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "codegen.h"
#include "fixup.h"
#include "fpfixup.h"
#include "segment.h"
#include "input.h"
#include "listing.h"
#include "reswords.h"

extern const struct opnd_class opnd_clstab[];
#if AVXSUPP
extern struct ReservedWord  ResWordTable[];
extern const uint_8               vex_flags[];
#endif

const char szNull[] = {"<NULL>"};

/* v2.03: OutputCodeByte no longer needed */
#define OutputCodeByte( x ) OutputByte( x )

/* segment order must match the one in special.h */
enum prefix_reg {
    PREFIX_ES = 0x26,
    PREFIX_CS = 0x2E,
    PREFIX_SS = 0x36,
    PREFIX_DS = 0x3E,
    PREFIX_FS = 0x64,
    PREFIX_GS = 0x65
};

static const char sr_prefix[] =
    { PREFIX_ES, PREFIX_CS, PREFIX_SS, PREFIX_DS, PREFIX_FS, PREFIX_GS };

static void output_opc( struct code_info *CodeInfo )
/**************************************************/
/*
 * - determine what code should be output and their order.
 * - output prefix bytes:
 *    - LOCK, REPxx,
 *    - FWAIT (not a prefix, but handled like one)
 *    - address size prefix 0x67
 *    - operand size prefix 0x66
 *    - segment override prefix, branch hints
 * - output opcode (1-3), "mod r/m" and "s-i-b" bytes.
 *
 * Note that jwasm follows Masm strictly here, even if it
 * contradicts Intel docs. For example, Masm always emits
 * the F2/F3/66 byte before a segment prefix, even if the
 * F2/F3/66 byte is a "mantadory prefix".
 */
{
    const struct instr_item *ins = CodeInfo->pinstr;
    uint_8           tmp;
    uint_8           fpfix = FALSE;

    DebugMsg1(("output_opc enter, ins.opc/rm=%X/%X, byte1_info=%X CodeInfo->rm=%X opsiz=%u\n", ins->opcode, ins->rm_byte, ins->byte1_info, CodeInfo->rm_byte, CodeInfo->prefix.opsiz ));
    /*
     * Output debug info - line numbers
     */
    if( Options.line_numbers )
        AddLinnumDataRef( get_curr_srcfile(), GetLineNumber() );

    /* if it's a FPU instr, reset opsiz */
    //if( ins->cpu & P_FPU_MASK ) {
    /* v2.02: if it's a FPU or MMX/SSE instr, reset opsiz!
     * [this code has been moved here from codegen()]
     */
    if( ins->cpu & ( P_FPU_MASK | P_MMX | P_SSEALL ) ) {
#if SSE4SUPP
        /* there are 2 exceptions. how to avoid this ugly hack? */
        if ( CodeInfo->token != T_CRC32 &&
            CodeInfo->token != T_POPCNT )
#endif
        CodeInfo->prefix.opsiz = FALSE;
    }

    /*
     * Check if CPU, FPU and extensions are within the limits
     */
    if( ( ins->cpu & P_CPU_MASK ) > ( ModuleInfo.curr_cpu & P_CPU_MASK )
        || ( ins->cpu & P_FPU_MASK ) > ( ModuleInfo.curr_cpu & P_FPU_MASK )
        || ( ins->cpu & P_EXT_MASK ) > ( ModuleInfo.curr_cpu & P_EXT_MASK ) ) {
        DebugMsg(("output_opc: wrong cpu setting: instr.cpu=%X, ModuleInfo.cpu=%X\n",
                  ins->cpu, ModuleInfo.curr_cpu ));
        /* if instruction is valid for 16bit cpu, but operands aren't,
         then display a more specific error message! */
        if( ins->cpu == P_386 &&
            ( ( InstrTable[ IndexFromToken( CodeInfo->token )].cpu & P_CPU_MASK ) <= P_386 ))
            EmitError( INSTRUCTION_FORM_REQUIRES_80386 );
        else
            EmitError( INSTRUCTION_OR_REGISTER_NOT_ACCEPTED_IN_CURRENT_CPU_MODE );
        //return( ERROR );
    }

    /*
     * Output FP fixup if required
     * the OPs with NOWAIT are the instructions beginning with
     * FN, except FNOP.
     * the OPs with WAIT are the instructions:
     * FCLEX, FDISI, FENI, FINIT, FSAVEx, FSTCW, FSTENVx, FSTSW
     */
    if(( ModuleInfo.emulator == TRUE ) &&
       ( CodeInfo->Ofssize == USE16 ) &&
       ( ins->cpu & P_FPU_MASK ) &&
       ( ins->allowed_prefix != AP_NO_FWAIT ) ) {
        fpfix = TRUE;
        /* v2.04: no error is returned */
        AddFloatingPointEmulationFixup( CodeInfo );
    }

    /*
     * Output instruction prefix LOCK, REP or REP[N]E|Z
     */
    if( CodeInfo->prefix.ins != EMPTY ) {
        tmp = InstrTable[ IndexFromToken( CodeInfo->prefix.ins )].allowed_prefix;
        /* instruction prefix must be ok. However, with -Zm, the plain REP
         * is also ok for instructions which expect REPxx.
         */
        if ( ModuleInfo.m510 == TRUE &&
            tmp == AP_REP &&
            ins->allowed_prefix == AP_REPxx )
            tmp = AP_REPxx;

        if( ins->allowed_prefix != tmp ) {
            EmitError( INSTRUCTION_PREFIX_NOT_ALLOWED );
        } else
            OutputCodeByte( InstrTable[ IndexFromToken( CodeInfo->prefix.ins )].opcode );
    }
    /*
     * Output FP FWAIT if required
     */
    if ( ins->cpu & P_FPU_MASK ) {
        if( CodeInfo->token == T_FWAIT ) {
            /* v2.04: Masm will always insert a NOP if emulation is active,
             * no matter what the current cpu is. The reason is simple: the
             * nop is needed because of the fixup which was inserted.
             */
            //if(( ModuleInfo.curr_cpu & P_CPU_MASK ) < P_386 ) {
            //    if(( ModuleInfo.emulator == TRUE ) && ( CodeInfo->Ofssize == USE16 )) {
            if( fpfix ) {
                OutputCodeByte( OP_NOP );
            }
        } else if( fpfix || ins->allowed_prefix == AP_FWAIT ) {
            OutputCodeByte( OP_WAIT );
        } else if( ins->allowed_prefix != AP_NO_FWAIT ) {
            /* implicit FWAIT synchronization for 8087 (CPU 8086/80186) */
            if(( ModuleInfo.curr_cpu & P_CPU_MASK ) < P_286 )
               OutputCodeByte( OP_WAIT );
        }
    }

    /*
     * check if address/operand size prefix is to be set
     */
    switch( ins->byte1_info ) {
    case F_16:
        if( CodeInfo->Ofssize >= USE32 ) CodeInfo->prefix.opsiz = TRUE;
        break;
    case F_32:
        if( CodeInfo->Ofssize == USE16 ) CodeInfo->prefix.opsiz = TRUE;
        break;
    case F_16A: /* 16-bit JCXZ and LOOPcc */
        /* doesnt exist for IA32+ */
        if( CodeInfo->Ofssize == USE32 ) CodeInfo->prefix.adrsiz = TRUE;
        break;
    case F_32A: /* 32-bit JECXZ and LOOPcc */
#if AMD64_SUPPORT
        /* in IA32+, the 32bit version gets an 0x67 prefix */
        if ( CodeInfo->Ofssize != USE32)  CodeInfo->prefix.adrsiz = TRUE;
#else
        if( CodeInfo->Ofssize == USE16 ) CodeInfo->prefix.adrsiz = TRUE;
#endif
        break;
    case F_0FNO66:
        CodeInfo->prefix.opsiz = FALSE;
        break;
#if AMD64_SUPPORT
    case F_48:
    case F_480F:
        CodeInfo->prefix.rex |= REX_W;
        break;
#endif
    }

#if AVXSUPP
    if ( !( ResWordTable[CodeInfo->token].flags & RWF_VEX ) ) {
#endif
        switch ( ins->byte1_info ) {
        case F_660F:
        case F_660F38:
        case F_660F3A:
            CodeInfo->prefix.opsiz = TRUE;
            break;
        case F_F20F:
        case F_F20F38: OutputCodeByte( 0xF2 ); break;
        case F_F3: /* PAUSE instruction */
        case F_F30F:   OutputCodeByte( 0xF3 ); break;
        }
#if AVXSUPP
    }
#endif
    /*
     * Output address and operand size prefixes.
     * These bytes are NOT compatible with FP emulation fixups,
     * which expect that the FWAIT/NOP first "prefix" byte is followed
     * by either a segment prefix or the opcode byte.
     * Neither Masm nor JWasm emit a warning, though.
     */
    if( CodeInfo->prefix.adrsiz == TRUE ) {
        OutputCodeByte( ADRSIZ );
#ifdef DEBUG_OUT
        if ( fpfix )
            DebugMsg(("output_opc: ERROR: FP emulation byte sequence destroyed by 32-bit address prefix!\n"));
#endif
    }
    if( CodeInfo->prefix.opsiz == TRUE ) {
#if 1
        if(( ModuleInfo.curr_cpu & P_CPU_MASK ) < P_386 ) {
            DebugMsg(("output_opc: instruction form requires 386\n"));
            EmitError( INSTRUCTION_FORM_REQUIRES_80386 );
            //return( ERROR ); /* v2.06: don't skip instruction */
        }
#endif
        OutputCodeByte( OPSIZ );
    }
    /*
     * Output segment prefix
     */
    if( CodeInfo->prefix.RegOverride != EMPTY ) {
        OutputCodeByte( sr_prefix[CodeInfo->prefix.RegOverride] );
    }

    if( ins->opnd_dir ) {
        /* The reg and r/m fields are backwards */
        tmp = CodeInfo->rm_byte;
        CodeInfo->rm_byte = ( tmp & 0xc0 ) | ((tmp >> 3) & 0x7) | ((tmp << 3) & 0x38);
#if AMD64_SUPPORT
        tmp = CodeInfo->prefix.rex;
        CodeInfo->prefix.rex = ( tmp & 0xFA ) | (( tmp & REX_R ) >> 2 ) | (( tmp & REX_B ) << 2 );
#endif
    }

#if AVXSUPP
    if ( ResWordTable[CodeInfo->token].flags & RWF_VEX ) {
        uint_8 lbyte = 0;
        switch ( ins->byte1_info ) {
        case F_660F:
        case F_660F38:
        case F_660F3A:
            lbyte |= 0x01;
            break;
        case F_F30F:
            lbyte |= 0x02;
            break;
        case F_F20F:
        case F_F20F38:
            lbyte |= 0x03;
            break;
        }

        if ( ( CodeInfo->opnd[OPND1].type & OP_YMM ) ||
            ( CodeInfo->opnd[OPND2].type & ( OP_YMM | OP_M256 ) ) ||
            ( CodeInfo->opnd[OPND1].type == OP_NONE && /* no operands? use VX_L flag from vex_flags[] */
             vex_flags[ CodeInfo->token - VEX_START ] & VX_L ) )
            lbyte |= 0x04;

        if ( CodeInfo->vexregop )
            lbyte |= ( ( 16 - CodeInfo->vexregop ) << 3 );
        else
            lbyte |= 0x78;

        /* emit 2 (0xC4) or 3 (0xC5) byte VEX prefix */
        if ( ins->byte1_info >= F_0F38 || ( CodeInfo->prefix.rex & ( REX_B | REX_X | REX_W ) ) ) {
            uint_8 byte1 = 0;
            OutputCodeByte( 0xC4 );
            switch ( ins->byte1_info ) {
            case F_0F38:
            case F_660F38:
            case F_F20F38:
                byte1 |= 0x02;
                break;
            case F_0F3A:
            case F_660F3A:
                byte1 |= 0x03;
                break;
            default:
                if ( ins->byte1_info >= F_0F )
                    byte1 |= 0x01;
            }
            byte1 |= (( CodeInfo->prefix.rex & REX_B ) ? 0 : 0x20 );
            byte1 |= (( CodeInfo->prefix.rex & REX_X ) ? 0 : 0x40 );
            byte1 |= (( CodeInfo->prefix.rex & REX_R ) ? 0 : 0x80 );
            OutputCodeByte( byte1 );
            lbyte |= ( ( CodeInfo->prefix.rex & REX_W ) ? 0x80 : 0 );
            OutputCodeByte( lbyte );
        } else {
            lbyte |= ( ( CodeInfo->prefix.rex & REX_R ) ? 0 : 0x80 );
            OutputCodeByte( 0xC5 );
            OutputCodeByte( lbyte );
        }
    } else {
#endif

#if AMD64_SUPPORT
    /* the REX prefix must be located after the other prefixes */
    if( CodeInfo->prefix.rex != 0 ) {
        if ( CodeInfo->Ofssize != USE64 ) {
            EmitError( INVALID_OPERAND_SIZE );
        }
        OutputCodeByte( CodeInfo->prefix.rex | 0x40 );
    }
#endif

    /*
     * Output extended opcode
     * special case for some 286 and 386 instructions
     * or 3DNow!, MMX and SSEx instructions
     */
    if ( ins->byte1_info >= F_0F ) {
        OutputCodeByte( EXTENDED_OPCODE );
        switch ( ins->byte1_info ) {
        case F_0F0F:   OutputCodeByte( EXTENDED_OPCODE ); break;
        case F_0F38:
        case F_F20F38:
        case F_660F38: OutputCodeByte( 0x38 );            break;
        case F_0F3A:
        case F_660F3A: OutputCodeByte( 0x3A );            break;
        }
    }

#if AVXSUPP
    }
#endif

    switch( ins->rm_info ) {
    case R_in_OP:
        OutputCodeByte( ins->opcode | ( CodeInfo->rm_byte & NOT_BIT_67 ) );
        break;
    case no_RM:
        OutputCodeByte( ins->opcode | CodeInfo->iswide );
        break;
    case no_WDS:
        CodeInfo->iswide = 0;
        /* no break */
    default: /* opcode (with w d s bits), rm-byte */
        /* don't emit opcode for 3DNow! instructions */
        if( ins->byte1_info != F_0F0F ) {
            OutputCodeByte( ins->opcode | CodeInfo->iswide | CodeInfo->opc_or );
        }
        /* emit ModRM byte; bits 7-6 = Mod, bits 5-3 = Reg, bits 2-0 = R/M */
        tmp = ins->rm_byte | CodeInfo->rm_byte;
        OutputCodeByte( tmp );

        if( ( CodeInfo->Ofssize == USE16 && CodeInfo->prefix.adrsiz == 0 ) ||
           ( CodeInfo->Ofssize == USE32 && CodeInfo->prefix.adrsiz == 1 ) )
            return; /* no SIB for 16bit */

        switch ( tmp & NOT_BIT_345 ) {
        case 0x04: /* mod = 00, r/m = 100, s-i-b is present */
        case 0x44: /* mod = 01, r/m = 100, s-i-b is present */
        case 0x84: /* mod = 10, r/m = 100, s-i-b is present */
            /* emit SIB byte; bits 7-6 = Scale, bits 5-3 = Index, bits 2-0 = Base */
            OutputCodeByte( CodeInfo->sib );
        }
    }

    return;
}

static void output_data( const struct code_info *CodeInfo, enum operand_type determinant, int index )
/***************************************************************************************************/
/*
 * output address displacement and immediate data;
 */
{
    int       size = 0;

    /* skip the memory operand for XLAT/XLATB and string instructions! */
    if ( CodeInfo->token == T_XLAT || CodeInfo->token == T_XLATB ||
        CodeInfo->pinstr->allowed_prefix == AP_REP ||
        CodeInfo->pinstr->allowed_prefix == AP_REPxx ) {
        /* v2.06: no need anymore to modify the fixup field, it's
         * used inside OutputBytes() only.
         */
        //CodeInfo->InsFixup[index] = NULL;
        return;
    }
#ifdef DEBUG_OUT
    if ( CodeInfo->opnd[index].InsFixup )
        DebugMsg1(("output_data(idx=%u, op=%" I32_SPEC "X [data=%" I32_SPEC "X fixup=%p typ=%u] ) enter [rm=%X]\n", index, determinant, CodeInfo->opnd[index].data32l, CodeInfo->opnd[index].InsFixup, CodeInfo->opnd[index].InsFixup->type ,CodeInfo->rm_byte ));
    else
        DebugMsg1(("output_data(idx=%u, op=%" I32_SPEC "X [data=%" I32_SPEC "X fixup=NULL] ) enter [rm=%X]\n", index, determinant, CodeInfo->opnd[index].data32l, CodeInfo->rm_byte ));
#endif

    /* determine size */

    if( determinant & OP_I8 ) {
        size = 1;
    } else if( determinant & OP_I16 ) {
        size = 2;
    } else if( determinant & OP_I32 ) {
        size = 4;
    } else if( determinant & OP_I48 ) {
        size = 6;
#if AMD64_SUPPORT
    } else if( determinant & OP_I64 ) {
        size = 8;
#endif
    } else if( determinant & OP_M_ANY ) {
        /* switch on the mode ( the leftmost 2 bits ) */
        switch( CodeInfo->rm_byte & BIT_67 ) {
        case MOD_01:  /* 8-bit displacement */
            size = 1;
            break;
        case MOD_00: /* direct; base and/or index with no disp */
            if( ( CodeInfo->Ofssize == USE16 && CodeInfo->prefix.adrsiz == 0 ) ||
               ( CodeInfo->Ofssize == USE32 && CodeInfo->prefix.adrsiz == 1 ) ) {
                if( ( CodeInfo->rm_byte & BIT_012 ) == RM_D16 ) {
                     size = 2; /* = size of displacement */
                }
            } else {
#if AMD64_SUPPORT
                /* v2.11: special case, 64-bit direct memory addressing, opcodes 0xA0 - 0xA3 */
                if( CodeInfo->Ofssize == USE64 && ( CodeInfo->pinstr->opcode & 0xFC ) == 0xA0 && CodeInfo->pinstr->byte1_info == 0 )
                    size = 8;
                else
#endif
                switch( CodeInfo->rm_byte & BIT_012 ) {
                case RM_SIB: /* 0x04 (equals register # for ESP) */
                    if( ( CodeInfo->sib & BIT_012 ) != RM_D32 ) {
                        break;  /* size = 0 */
                    }
                    /* no break */
                case RM_D32: /* 0x05 (equals register # for EBP) */
                    size = 4; /* = size of displacement */
#if AMD64_SUPPORT
                    /* v2.11: overflow check for 64-bit added */
                    if ( CodeInfo->Ofssize == USE64 && CodeInfo->opnd[index].data64 >= 0x80000000 && CodeInfo->opnd[index].data64 < 0xffffffff80000000 )
                        EmitErr( INVALID_INSTRUCTION_OPERANDS );
#endif
                }
            }
            break;
        case MOD_10:  /* 16- or 32-bit displacement */
            if( ( CodeInfo->Ofssize == USE16 && CodeInfo->prefix.adrsiz == 0 ) ||
               ( CodeInfo->Ofssize == USE32 && CodeInfo->prefix.adrsiz == 1 ) ) {
                size = 2;
            } else {
                size = 4;
            }
        }
    }
#ifdef DEBUG_OUT
    if ( size > 4 )
        DebugMsg1(( "output_data: size=%u cont=%" I64_SPEC "X\n", size, CodeInfo->opnd[index].data64 ));
    else if ( size )
        DebugMsg1(( "output_data: size=%u cont=%" I32_SPEC "X\n", size, CodeInfo->opnd[index].data32l ));
    else
        DebugMsg1(( "output_data: size=0\n" ));
#endif
    if ( size ) {
        if ( CodeInfo->opnd[index].InsFixup ) {
            /* v2.07: fixup type check moved here */
            if ( Parse_Pass > PASS_1 )
                if ( ( 1 << CodeInfo->opnd[index].InsFixup->type ) & ModuleInfo.fmtopt->invalid_fixup_type ) {
                    EmitErr( UNSUPPORTED_FIXUP_TYPE,
                           ModuleInfo.fmtopt->formatname,
                           CodeInfo->opnd[index].InsFixup->sym ? CodeInfo->opnd[index].InsFixup->sym->name : szNull );
                    /* don't exit! */
                }
            if ( write_to_file ) {
                CodeInfo->opnd[index].InsFixup->locofs = GetCurrOffset();
                OutputBytes( (unsigned char *)&CodeInfo->opnd[index].data32l,
                            size, CodeInfo->opnd[index].InsFixup );
                return;
            }
        }
        OutputBytes( (unsigned char *)&CodeInfo->opnd[index].data32l, size, NULL );
    }
    return;
}

static ret_code check_3rd_operand( struct code_info *CodeInfo )
/*************************************************************/
{
    if( ( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_NONE ) ||
       ( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_HID ) )
        return( ( CodeInfo->opnd[OPND3].type == OP_NONE ) ? NOT_ERROR : ERROR );

    /* current variant needs a 3rd operand */
    DebugMsg1(("check_3rd_operand: tab=%X <-> codeinfo=%X\n", opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd, CodeInfo->opnd[OPND3].type ));

    switch ( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd ) {
    case OP3_CL:
        if ( CodeInfo->opnd[OPND3].type == OP_CL )
            return( NOT_ERROR );
        break;
    case OP3_I8_U: /* IMUL, SHxD, a few MMX/SSE */
        /* for IMUL, the operand is signed! */
        if ( ( CodeInfo->opnd[OPND3].type & OP_I ) && CodeInfo->opnd[OPND3].data32l >= -128 ) {
            if ( ( CodeInfo->token == T_IMUL && CodeInfo->opnd[OPND3].data32l < 128 ) ||
                ( CodeInfo->token != T_IMUL && CodeInfo->opnd[OPND3].data32l < 256 ) ) {
                CodeInfo->opnd[OPND3].type = OP_I8;
                return( NOT_ERROR );
            }
        }
        break;
    case OP3_I: /* IMUL */
        if ( CodeInfo->opnd[OPND3].type & OP_I )
            return( NOT_ERROR );
        break;
    case OP3_XMM0:
#if AVXSUPP
        /* for VEX encoding, XMM0 has the meaning: any XMM/YMM register */
        if ( CodeInfo->token >= VEX_START ) {
            if ( CodeInfo->opnd[OPND3].type & ( OP_XMM | OP_YMM ) )
                return( NOT_ERROR );
        } else
#endif
        if ( CodeInfo->opnd[OPND3].type == OP_XMM &&
            CodeInfo->opnd[OPND3].data32l == 0 )
            return( NOT_ERROR );
        break;
    }
    return( ERROR );
}

static void output_3rd_operand( struct code_info *CodeInfo )
/**********************************************************/
{
    if( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_I8_U ) {
        DebugMsg1(("output_3rd_operand, expected I8, op3=%" I32_SPEC "X\n", CodeInfo->opnd[OPND3].type ));
        /* v2.06: the type has been checked already! */
        //if( CodeInfo->opnd_type[OPND3] & OP_I ) {
        output_data( CodeInfo, OP_I8, OPND3 );
        //} else {
        //    EmitError( INVALID_INSTRUCTION_OPERANDS );
        //    return;
        //}
    } else if( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_I ) {
        output_data( CodeInfo, CodeInfo->opnd[OPND3].type, OPND3 );
    } else if( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_HID ) {
        DebugMsg1(("output_3rd_operand, expected OP3_HID, op3=%" I32_SPEC "X\n", CodeInfo->opnd[OPND3].type ));
        /* v2.06: to avoid having to add 3*8 operand categories there's a
         * hard-wired peculiarity for the "hidden" 3rd operand: it's calculated
         * directly from the instruction token. in instruct.h, CMPEQPD must
         * be first and the order of the following CMP entries must not be
         * changed.
         */
        //CodeInfo->data[OPND3] = opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd & ~OP3_HID;
        CodeInfo->opnd[OPND3].data32l = ( CodeInfo->token - T_CMPEQPD ) % 8;
        CodeInfo->opnd[OPND3].InsFixup = NULL;
        output_data( CodeInfo, OP_I8, OPND3 );
    }
#if AVXSUPP
    else if( CodeInfo->token >= VEX_START &&
            opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd == OP3_XMM0 ) {
        CodeInfo->opnd[OPND3].data32l = ( CodeInfo->opnd[OPND3].data32l << 4 );
        output_data( CodeInfo, OP_I8, OPND3 );
    }
#endif
    return;
}

static ret_code match_phase_3( struct code_info *CodeInfo, enum operand_type opnd1 )
/***********************************************************************************
 * - this routine will look up the assembler opcode table and try to match
 *   the second operand with what we get;
 * - if second operand match then it will output code; if not, pass back to
 *   codegen() and continue to scan InstrTable;
 * - possible return codes: NOT_ERROR (=done), ERROR (=nothing found)
 */
{
    enum operand_type    determinant = opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type[OPND1]; /* remember first op type */
    enum operand_type    opnd2 = CodeInfo->opnd[OPND2].type;
    enum operand_type    tbl_op2;

    DebugMsg1(("match_phase_3 enter, opnd1=%" I32_SPEC "X, searching op2=%" I32_SPEC "X\n", opnd1, opnd2 ));

#if AVXSUPP
    if ( CodeInfo->token >= VEX_START && ( vex_flags[ CodeInfo->token - VEX_START ] & VX_L ) ) {
        if ( CodeInfo->opnd[OPND1].type & ( OP_YMM | OP_M256) ) {
            if ( opnd2 & OP_YMM )
                opnd2 |= OP_XMM;
            else if ( opnd2 & OP_M256 )
                opnd2 |= OP_M128;
            else if ( opnd2 & OP_M128 )
                opnd2 |= OP_M64;
            else if ( ( opnd2 & OP_XMM ) && !( vex_flags[ CodeInfo->token - VEX_START ] & VX_HALF ) ) {
                EmitError( INSTRUCTION_OR_REGISTER_NOT_ACCEPTED_IN_CURRENT_CPU_MODE );
                return( ERROR );
            }
        }
#if 1
        /* may be necessary to cover the cases where the first operand is a memory operand
         * "without size" and the second operand is a ymm register
         */
        else if ( CodeInfo->opnd[OPND1].type == OP_M ) {
            if ( opnd2 & OP_YMM )
                opnd2 |= OP_XMM;
        }
#endif
    }
#endif
    do  {
        tbl_op2 = opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type[OPND2];
        DebugMsg1(("match_phase_3: instr table op2=%" I32_SPEC "X\n", tbl_op2 ));
        switch( tbl_op2 ) {
        case OP_I: /* arith, MOV, IMUL, TEST */
            if( opnd2 & tbl_op2 ) {
                DebugMsg1(("match_phase_3: matched OP_I\n"));
                /* This branch exits with either ERROR or NOT_ERROR.
                 * So it can modify the CodeInfo fields without harm.
                 */
                if( opnd1 & OP_R8 ) {
                    /* 8-bit register, so output 8-bit data */
                    /* v2.04: the check has already happened in check_size() or idata_xxx() */
                    //if( Parse_Pass == PASS_1 && !InRange( operand, 1 ) ) {
                    //    DebugMsg(("imm const too large (08): %X\n", operand));
                    //    EmitWarn( 1, IMMEDIATE_CONSTANT_TOO_LARGE );
                    //}
                    CodeInfo->prefix.opsiz = FALSE;
                    opnd2 = OP_I8;
                    if( CodeInfo->opnd[OPND2].InsFixup != NULL ) {
                    /* v1.96: make sure FIX_HIBYTE isn't overwritten! */
                        if ( CodeInfo->opnd[OPND2].InsFixup->type != FIX_HIBYTE )
                            CodeInfo->opnd[OPND2].InsFixup->type = FIX_OFF8;
                    }
                } else if( opnd1 & OP_R16 ) {
                    /* v2.04: the check has already happened in check_size() or idata_xxx() */
                    //if( Parse_Pass == PASS_1 && !InRange( operand, 2 ) ) {
                    //    DebugMsg(("imm const too large (16): %X\n", operand));
                    //    EmitWarn( 1, IMMEDIATE_CONSTANT_TOO_LARGE );
                    //}
                    /* 16-bit register, so output 16-bit data */
                    opnd2 = OP_I16;
#if AMD64_SUPPORT
                } else if( opnd1 & (OP_R32 | OP_R64 ) ) {
#else
                } else if( opnd1 & OP_R32 ) {
#endif
                    /* 32- or 64-bit register, so output 32-bit data */
                    CodeInfo->prefix.opsiz = CodeInfo->Ofssize ? 0 : 1;/* 12-feb-92 */
                    opnd2 = OP_I32;
                } else if( opnd1 & OP_M ) {
                    /* there is no reason this should be only for T_MOV */
                    switch( OperandSize( opnd1, CodeInfo ) ) {
                    case 1:
                        opnd2 = OP_I8;
                        CodeInfo->prefix.opsiz = FALSE;
                        break;
                    case 2:
                        opnd2 = OP_I16;
                        CodeInfo->prefix.opsiz = CodeInfo->Ofssize ? 1 : 0;
                        break;
#if AMD64_SUPPORT
                        /* mov [mem], imm64 doesn't exist. It's ensured that
                         * immediate data is 32bit only
                         */
                    case 8:
#endif
                    case 4:
                        opnd2 = OP_I32;
                        CodeInfo->prefix.opsiz = CodeInfo->Ofssize ? 0 : 1;
                        break;
                    default:
                        EmitError( INVALID_INSTRUCTION_OPERANDS );
                        //return( ERROR ); /* v2.06: don't exit */
                    }
                }
                output_opc( CodeInfo );
                output_data( CodeInfo, opnd1, OPND1 );
                output_data( CodeInfo, opnd2, OPND2 );
                return( NOT_ERROR );
            }
            break;
        case OP_I8_U: /* shift+rotate, ENTER, BTx, IN, PSxx[D|Q|W] */
            if( opnd2 & tbl_op2 ) {
                DebugMsg1(("match_phase_3: matched OP_I8_U\n"));
                if ( CodeInfo->const_size_fixed && opnd2 != OP_I8 )
                    break;
                /* v2.03: lower bound wasn't checked */
                /* range of unsigned 8-bit is -128 - +255 */
                if( CodeInfo->opnd[OPND2].data32l <= UCHAR_MAX && CodeInfo->opnd[OPND2].data32l >= SCHAR_MIN ) {
                    /* v2.06: if there's an external, adjust the fixup if it is > 8-bit */
                    if ( CodeInfo->opnd[OPND2].InsFixup != NULL ) {
                        if ( CodeInfo->opnd[OPND2].InsFixup->type == FIX_OFF16 ||
                            CodeInfo->opnd[OPND2].InsFixup->type == FIX_OFF32 )
                            CodeInfo->opnd[OPND2].InsFixup->type = FIX_OFF8;
                    }
                    /* the SSE4A EXTRQ instruction will need this! */
                    //if( check_3rd_operand( CodeInfo ) == ERROR )
                    //  break;
                    output_opc( CodeInfo );
                    output_data( CodeInfo, opnd1, OPND1 );
                    output_data( CodeInfo, OP_I8, OPND2 );
                    //if( CodeInfo->pinstr->opnd_type_3rd != OP3_NONE )
                    //output_3rd_operand( CodeInfo );
                    return( NOT_ERROR );
                }
            }
            break;
        case OP_I8: /* arith, IMUL */
            /* v2.06: this case has been rewritten */

            /* v2.04: added */
            if( ModuleInfo.NoSignExtend &&
               ( CodeInfo->token == T_AND ||
                CodeInfo->token == T_OR ||
                CodeInfo->token == T_XOR ) )
                break;

            /* v2.14: ensure that InsFixup->sym is set - it always should, since a fixup is generated,
             * but obviously there are cases where it is NOT!
             */
            /* v2.11: skip externals - but don't skip undefines; forward8.asm */
            //if ( CodeInfo->opnd[OPND2].InsFixup != NULL ) /* external? then skip */
            //if ( CodeInfo->opnd[OPND2].InsFixup != NULL && CodeInfo->opnd[OPND2].InsFixup->sym->state != SYM_UNDEFINED ) /* external? then skip */
            if ( CodeInfo->opnd[OPND2].InsFixup != NULL && CodeInfo->opnd[OPND2].InsFixup->sym &&
                CodeInfo->opnd[OPND2].InsFixup->sym->state != SYM_UNDEFINED ) /* external? then skip */
                break;

            if ( CodeInfo->const_size_fixed == FALSE )
                if ( ( opnd1 & ( OP_R16 | OP_M16 ) ) && (int_8)CodeInfo->opnd[OPND2].data32l == (int_16)CodeInfo->opnd[OPND2].data32l )
                    tbl_op2 |= OP_I16;
                else if ( ( opnd1 & ( OP_RGT16 | OP_MGT16 ) ) && (int_8)CodeInfo->opnd[OPND2].data32l == (int_32)CodeInfo->opnd[OPND2].data32l )
                    tbl_op2 |= OP_I32;

            if( opnd2 & tbl_op2 ) {
                DebugMsg1(("match_phase_3: matched OP_I8\n"));
                output_opc( CodeInfo );
                output_data( CodeInfo, opnd1, OPND1 );
                output_data( CodeInfo, OP_I8, OPND2 );
                return( NOT_ERROR );
            }
            break;
        case OP_I_1: /* shift ops */
            if( opnd2 & tbl_op2 ) {
               if ( CodeInfo->opnd[OPND2].data32l == 1 ) {
                   DebugMsg1(("match_phase_3: matched OP_I_1\n"));
                   output_opc( CodeInfo );
                   output_data( CodeInfo, opnd1, OPND1 );
                   /* the immediate is "implicite" */
                   return( NOT_ERROR );
               }
            }
            break;
        default:
            /* v2.06: condition made more restrictive */
            //if( ( opnd2 & tbl_op2 ) || (CodeInfo->mem_type == MT_EMPTY && (opnd2 & OP_M_ANY) && (tbl_op2 & OP_M_ANY) )) {
            if( opnd2 & tbl_op2 ) {
                if( check_3rd_operand( CodeInfo ) == ERROR )
                    break;
                DebugMsg1(("match_phase_3: matched opnd2\n" ));
                output_opc( CodeInfo );
                if ( opnd1 & (OP_I_ANY | OP_M_ANY ) )
                    output_data( CodeInfo, opnd1, OPND1 );
                if ( opnd2 & (OP_I_ANY | OP_M_ANY ) )
                    output_data( CodeInfo, opnd2, OPND2 );
                //if( CodeInfo->pinstr->opnd_type_3rd != OP3_NONE )
                if( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type_3rd != OP3_NONE )
                    output_3rd_operand( CodeInfo );
                if( CodeInfo->pinstr->byte1_info == F_0F0F ) /* output 3dNow opcode? */
                    OutputCodeByte( CodeInfo->pinstr->opcode | CodeInfo->iswide );
                return( NOT_ERROR );
            }
            break;
        }
        CodeInfo->pinstr++;
    } while ( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type[OPND1] == determinant && CodeInfo->pinstr->first == FALSE );
    CodeInfo->pinstr--; /* pointer will be increased in codegen() */
    DebugMsg1(("match_phase_3: returns EMPTY\n"));
    return( ERROR );
}

static ret_code check_operand_2( struct code_info *CodeInfo, enum operand_type opnd1 )
/*************************************************************************************
 * check if a second operand has been entered.
 * If yes, call match_phase_3();
 * else emit opcode and optional data.
 * possible return codes: ERROR (=nothing found), NOT_ERROR (=done)
 */
{
    if( CodeInfo->opnd[OPND2].type == OP_NONE ) {

        if( opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type[OPND2] != OP_NONE )
            return( ERROR ); /* doesn't match */

        /* 1 opnd instruction found */

        /* v2.06: added check for unspecified size of mem op */
        if ( opnd1 == OP_M ) {
            const struct instr_item *next = CodeInfo->pinstr+1;
            if ( ( opnd_clstab[next->opclsidx].opnd_type[OPND1] & OP_M ) &&
                next->first == FALSE )
                /* skip error if mem op is a forward reference */
                /* v2.06b: added "undefined" check */
                if ( CodeInfo->undef_sym == FALSE &&
                    ( CodeInfo->opnd[OPND1].InsFixup == NULL ||
                     CodeInfo->opnd[OPND1].InsFixup->sym == NULL ||
                     CodeInfo->opnd[OPND1].InsFixup->sym->state != SYM_UNDEFINED ) ) {
                    DebugMsg(("check_operand_2: error: undef_sym=%u Fixup[0]=%X [%s]\n",
                              CodeInfo->undef_sym, CodeInfo->opnd[OPND1].InsFixup,
                              CodeInfo->opnd[OPND1].InsFixup ? CodeInfo->opnd[OPND1].InsFixup->sym ? CodeInfo->opnd[OPND1].InsFixup->sym->name : "NULL" : "NULL" ));
                    EmitErr( INSTRUCTION_OPERAND_MUST_HAVE_SIZE );
                }
        }

        output_opc( CodeInfo );
        output_data( CodeInfo, opnd1, OPND1 );
#if AMD64_SUPPORT
        if ( CodeInfo->Ofssize == USE64 && CodeInfo->opnd[OPND1].InsFixup && CodeInfo->opnd[OPND1].InsFixup->type == FIX_RELOFF32 )
            CodeInfo->opnd[OPND1].InsFixup->addbytes = GetCurrOffset() - CodeInfo->opnd[OPND1].InsFixup->locofs;
#endif
        return( NOT_ERROR );
    }

    /* check second operand */
    if ( match_phase_3( CodeInfo, opnd1 ) == NOT_ERROR ) {
#if AMD64_SUPPORT
        /* for rip-relative fixups, the instruction end is needed */
        if ( CodeInfo->Ofssize == USE64 ) {
            if ( CodeInfo->opnd[OPND1].InsFixup && CodeInfo->opnd[OPND1].InsFixup->type == FIX_RELOFF32 )
                CodeInfo->opnd[OPND1].InsFixup->addbytes = GetCurrOffset() - CodeInfo->opnd[OPND1].InsFixup->locofs;
            if ( CodeInfo->opnd[OPND2].InsFixup && CodeInfo->opnd[OPND2].InsFixup->type == FIX_RELOFF32 )
                CodeInfo->opnd[OPND2].InsFixup->addbytes = GetCurrOffset() - CodeInfo->opnd[OPND2].InsFixup->locofs;
        }
#endif
        return( NOT_ERROR );
    }
    return( ERROR );
}

ret_code codegen( struct code_info *CodeInfo, uint_32 oldofs )
/*************************************************************
 * - codegen() will look up the assembler opcode table and try to find
 *   a matching first operand;
 * - if one is found then it will call check_operand_2() to determine
 *   if further operands also match; else, it must be error.
 */
{
    ret_code           retcode = ERROR;
    enum operand_type  opnd1;
    enum operand_type  tbl_op1;

    /* privileged instructions ok? */
    if( ( CodeInfo->pinstr->cpu & P_PM ) > ( ModuleInfo.curr_cpu & P_PM ) ) {
        EmitError( INSTRUCTION_OR_REGISTER_NOT_ACCEPTED_IN_CURRENT_CPU_MODE );
        return( ERROR );
    }
    opnd1 = CodeInfo->opnd[OPND1].type;

    /* if first operand is immediate data, set compatible flags */
    if( opnd1 & OP_I ) {
        if( opnd1 == OP_I8 ) {
            opnd1 = OP_IGE8;
        } else if( opnd1 == OP_I16 ) {
            opnd1 = OP_IGE16;
        }
    }

#if AVXSUPP
    if ( CodeInfo->token >= VEX_START && ( vex_flags[ CodeInfo->token - VEX_START ] & VX_L ) ) {
        if ( opnd1 & ( OP_YMM | OP_M256 ) ) {
            if ( CodeInfo->opnd[OPND2].type & OP_XMM && !( vex_flags[ CodeInfo->token - VEX_START ] & VX_HALF ) ) {
                EmitErr( INVALID_INSTRUCTION_OPERANDS );
                return( ERROR );
            }
            if ( opnd1 & OP_YMM )
                opnd1 |= OP_XMM;
            else
                opnd1 |= OP_M128;
        }
    }
#endif

#if AMD64_SUPPORT
    DebugMsg1(("codegen(ofs=%X): %s opnd1=%X codeinfo: ofssize=%u wide=%u rm=%Xh sib=%Xh rex=%Xh opsiz=%u\n",
               CurrSeg->sym.offset, GetResWName( CodeInfo->token, NULL ),
               opnd1, CodeInfo->Ofssize, CodeInfo->iswide,
               CodeInfo->rm_byte, CodeInfo->sib,
               CodeInfo->prefix.rex, CodeInfo->prefix.opsiz ));
#endif
    /* scan the instruction table for a matching first operand */
    do  {
        tbl_op1 = opnd_clstab[CodeInfo->pinstr->opclsidx].opnd_type[OPND1];

        //DebugMsg1(("codegen: table.op1=%X\n", tbl_op1 ));

        /* v2.06: simplified */
        if ( tbl_op1 == OP_NONE && opnd1 == OP_NONE ) {
            output_opc( CodeInfo );
            if ( CurrFile[LST] )
                LstWrite( LSTTYPE_CODE, oldofs, NULL );
            return( NOT_ERROR );
        } else if ( opnd1 & tbl_op1 ) {
            /* for immediate operands, the idata type has sometimes
             * to be modified in opnd_type[OPND1], to make output_data()
             * emit the correct number of bytes. */
            switch( tbl_op1 ) {
            case OP_I32: /* CALL, JMP, PUSHD */
            case OP_I16: /* CALL, JMP, RETx, ENTER, PUSHW */
                retcode = check_operand_2( CodeInfo, tbl_op1 );
                break;
            case OP_I8_U: /* INT xx; OUT xx, AL */
                if( CodeInfo->opnd[OPND1].data32l <= UCHAR_MAX && CodeInfo->opnd[OPND1].data32l >= SCHAR_MIN ) {
                    retcode = check_operand_2( CodeInfo, OP_I8 );
                }
                break;
            case OP_I_3: /* INT 3 */
                if ( CodeInfo->opnd[OPND1].data32l == 3 ) {
                    retcode = check_operand_2( CodeInfo, OP_NONE );
                }
                break;
            default:
                retcode = check_operand_2( CodeInfo, CodeInfo->opnd[OPND1].type );
                break;
            }
            if( retcode == NOT_ERROR ) {
                if ( CurrFile[LST] )
                    LstWrite( LSTTYPE_CODE, oldofs, NULL );
                return( NOT_ERROR );
            }
        }
        CodeInfo->pinstr++;
    } while ( CodeInfo->pinstr->first == FALSE );

    DebugMsg(("codegen: no matching format found\n"));
    EmitError( INVALID_INSTRUCTION_OPERANDS );
    return( ERROR );
}

