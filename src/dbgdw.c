
/*****************************************************************************
 *
 * support for DWARF debugging info;
 * added for elf32/64 formats in v2.21.
 *
 ****************************************************************************/

#include <ctype.h>
#include <time.h>
#include <stddef.h>

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "fixup.h"
#include "segment.h"
#include "myassert.h"

#ifndef DWARF_SUPP
#define DWARF_SUPP 0
#endif

#if DWARF_SUPP

#include "linnum.h"
#include "dbgdw.h"

enum dwarf_sections {
    DWINFO_IDX,
    DWABBREV_IDX,
    DWLINE_IDX,
    NUM_DWSEGS
};

struct dwarfobj {
    struct dsym *dwarf_seg[NUM_DWSEGS];
};

static const char *dwarf_segnames[] = {
    ".debug_info",
    ".debug_abbrev",
    ".debug_line",
};

#define DWLINE_OPCODE_BASE 13 /* max is 13 */
#define DW_MIN_INSTR_LENGTH 1
#define DWLINE_BASE (-1)
#define DWLINE_RANGE 4

enum {
    NULL_ABBREV_CODE = 0,
    COMPUNIT_ABBREV_CODE,
    //LABEL_ABBREV_CODE,
    //VARIABLE_ABBREV_CODE,
};

#pragma pack( 1 )

static const char FlatStandardAbbrevs[] = {
    COMPUNIT_ABBREV_CODE,
    DW_TAG_compile_unit,
    DW_CHILDREN_no,
    DW_AT_low_pc,       DW_FORM_addr,
    DW_AT_high_pc,      DW_FORM_addr,
    DW_AT_stmt_list,    DW_FORM_data4,
    DW_AT_name,         DW_FORM_string,
    0,                  0,
#if 0
    LABEL_ABBREV_CODE,
    DW_TAG_label,
    DW_CHILDREN_no,
    DW_AT_low_pc,       DW_FORM_addr,
    DW_AT_external,     DW_FORM_flag,
    DW_AT_name,         DW_FORM_string,
    0,                  0,
    VARIABLE_ABBREV_CODE,
    DW_TAG_variable,
    DW_CHILDREN_no,
    DW_AT_low_pc,       DW_FORM_addr,
    DW_AT_external,     DW_FORM_flag,
    DW_AT_name,         DW_FORM_string,
    0,                  0,
#endif
    0,                  0
};

struct dwarf_info32 {
    struct dwarf_compilation_unit_header32 hdr;
    unsigned char abbrev_code;
    uint_32 low_pc;
    uint_32 high_pc;
    uint_32 stmt_list;
    char name[1];
};

struct dwarf_info64 {
    struct dwarf_compilation_unit_header32 hdr;
    unsigned char abbrev_code;
    uint_64 low_pc;
    uint_64 high_pc;
    uint_32 stmt_list;
    char name[1];
};

#pragma pack()

static void dwarf_set_info( struct dwarfobj *obj, struct dsym *seg_info )
/***********************************************************************/
{
    int size;
    struct dsym *curr;
    struct dwarf_info32 *p;
    struct fixup *fixup;

    size = strlen( ModuleInfo.g.FNames[0].fname );
    size += ModuleInfo.defOfssize == USE64 ? sizeof( struct dwarf_info64 ): sizeof( struct dwarf_info32 );
    seg_info->sym.max_offset = size;
    seg_info->e.seginfo->CodeBuffer = LclAlloc( size );
    p = (struct dwarf_info32 *)seg_info->e.seginfo->CodeBuffer;
    p->hdr.unit_length = size - 4;
    p->hdr.version = 2;

    p->hdr.debug_abbrev_offset = 0; /* needs a fixup */
    fixup = FixupCreate( (struct asym *)obj->dwarf_seg[DWABBREV_IDX], FIX_OFF32, OPTJ_NONE );
    fixup->locofs = offsetof(struct dwarf_info32, hdr.debug_abbrev_offset);
    store_fixup( fixup, seg_info, (int_32 *)&p->hdr.debug_abbrev_offset );

    p->hdr.address_size = ModuleInfo.defOfssize == USE64 ? 8 : 4;
    p->abbrev_code = COMPUNIT_ABBREV_CODE;

    /* search for the first segment with line numbers */
    for( curr = SymTables[TAB_SEG].head; curr; curr = curr->next )
        if ( curr->e.seginfo->LinnumQueue )
            break;

    if ( curr ) {
        if ( ModuleInfo.defOfssize == USE64 ) {
            struct dwarf_info64 *p;
            p = (struct dwarf_info64 *)seg_info->e.seginfo->CodeBuffer;

            p->low_pc = 0;
            fixup = FixupCreate( &curr->sym, FIX_OFF64, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info64, low_pc);
            store_fixup( fixup, seg_info, (int_32 *)&p->low_pc );

            p->high_pc = curr->sym.max_offset;
            fixup = FixupCreate( &curr->sym, FIX_OFF64, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info64, high_pc);
            store_fixup( fixup, seg_info, (int_32 *)&p->high_pc );

            p->stmt_list = 0; /* needs a fixup */
            fixup = FixupCreate( (struct asym *)obj->dwarf_seg[DWLINE_IDX], FIX_OFF32, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info64, stmt_list);
            store_fixup( fixup, seg_info, (int_32 *)&p->stmt_list );

            strcpy( (char *)&p->name, ModuleInfo.g.FNames[0].fname );
        } else {
            p->low_pc = 0;
            fixup = FixupCreate( &curr->sym, FIX_OFF32, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info32, low_pc);
            store_fixup( fixup, seg_info, (int_32 *)&p->low_pc );

            p->high_pc = curr->sym.max_offset;
            fixup = FixupCreate( &curr->sym, FIX_OFF32, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info32, high_pc);
            store_fixup( fixup, seg_info, (int_32 *)&p->high_pc );

            p->stmt_list = 0; /* needs a fixup */
            fixup = FixupCreate( (struct asym *)obj->dwarf_seg[DWLINE_IDX], FIX_OFF32, OPTJ_NONE );
            fixup->locofs = offsetof(struct dwarf_info32, stmt_list);
            store_fixup( fixup, seg_info, (int_32 *)&p->stmt_list );

            strcpy( (char *)&p->name, ModuleInfo.g.FNames[0].fname );
        }
    }

    return;
}

static void dwarf_set_abbrev( struct dwarfobj *obj, struct dsym *curr )
/*********************************************************************/
{
    int size = sizeof ( FlatStandardAbbrevs );

    curr->sym.max_offset = size;
    curr->e.seginfo->CodeBuffer = LclAlloc( size );
    memcpy( curr->e.seginfo->CodeBuffer, FlatStandardAbbrevs, sizeof( FlatStandardAbbrevs ) );
    return;
}

typedef int dw_addr_delta;
typedef int dw_sconst;

unsigned char *LEB128( unsigned char *buf, dw_sconst value )
/**********************************************************/
{
    unsigned char byte;

    /* we can only handle an arithmetic right shift */
    if( value >= 0 ) {
        for( ;; ) {
            byte = value & 0x7f;
            value >>= 7;
            if( value == 0 && ( byte & 0x40 ) == 0 ) break;
            *buf++ = byte | 0x80;
        }
    } else {
        for( ;; ) {
            byte = value & 0x7f;
            value >>= 7;
            if( value == -1 && ( byte & 0x40 ) ) break;
            *buf++ = byte | 0x80;
        }
    }
    *buf++ = byte;
    return( buf );
}


static int dwarf_line_gen( int line_incr, int addr_incr, unsigned char *buf )
/***************************************************************************/
{
    unsigned int        opcode;
    unsigned            size;
    uint_8              *end;
    dw_addr_delta       addr;

    DebugMsg(("dwarf_line_gen: line_incr=%d, addr_incr=%d\n", line_incr, addr_incr ));
    size = 0;
    if( line_incr < DWLINE_BASE || line_incr > DWLINE_BASE + DWLINE_RANGE - 1) {
        /* line_incr is out of bounds... emit standard opcode */
        buf[ 0 ] = DW_LNS_advance_line;
        size = LEB128( buf + 1, line_incr ) - buf;
        line_incr = 0;
    }

    if( addr_incr < 0 ) {
        buf[ size ] = DW_LNS_advance_pc;
        size = LEB128( buf + size + 1, addr_incr ) - buf;
        addr_incr = 0;
    } else {
        addr_incr /= DW_MIN_INSTR_LENGTH;
    }
    if( addr_incr == 0 && line_incr == 0 ) {
        buf[size] = DW_LNS_copy;
        return size + 1;
    }

    /* calculate the opcode with overflow checks */
    line_incr -= DWLINE_BASE;
    opcode = DWLINE_RANGE * addr_incr;
    if( opcode < addr_incr ) goto overflow;
    if( opcode + line_incr < opcode ) goto overflow;
    opcode += line_incr;

    /* can we use a special opcode? */
    if( opcode <= 255 - DWLINE_OPCODE_BASE ) {
        buf[ size ] = opcode + DWLINE_OPCODE_BASE;
        return size + 1;
    }

    /*
        We can't use a special opcode directly... but we may be able to
        use a CONST_ADD_PC followed by a special opcode.  So we calculate
        if addr_incr lies in this range.  MAX_ADDR_INCR is the addr
        increment for special opcode 255.
    */
#define MAX_ADDR_INCR   ( ( 255 - DWLINE_OPCODE_BASE ) / DWLINE_RANGE )

    if( addr_incr < 2*MAX_ADDR_INCR ) {
        buf[ size ] = DW_LNS_const_add_pc;
        size++;
        buf[ size ] = opcode - MAX_ADDR_INCR*DWLINE_RANGE + DWLINE_OPCODE_BASE;
        return size + 1;
    }

    /*
        Emit an ADVANCE_PC followed by a special opcode.

        We use MAX_ADDR_INCR - 1 to prevent problems if special opcode
        255 - DWLINE_OPCODE_BASE - DWLINE_BASE + 1 isn't an integral multiple
        of DWLINE_RANGE.
    */
overflow:
    buf[ size ] = DW_LNS_advance_pc;
    if( line_incr == 0 - DWLINE_BASE ) {
        opcode = DW_LNS_copy;
    } else {
        addr = addr_incr % ( MAX_ADDR_INCR - 1 );
        addr_incr -= addr;
        opcode = line_incr + ( DWLINE_RANGE * addr ) + DWLINE_OPCODE_BASE;
    }
    end = LEB128( buf + size + 1, addr_incr );
    *end++ = opcode;
    return end - buf;
}

static const unsigned char stdopsparms[] = {0,1,1,1,1,0,0,0,1,0,0,1};

static void dwarf_set_line( struct dwarfobj *obj, struct dsym *seg_linenum )
/**************************************************************************/
{
    int count;
    struct dwarf_stmt_header32 *p;
    unsigned char *px;
    struct dsym *curr;
    struct fixup *fixup;

    DebugMsg(("dwarf_set_line: enter\n" ));
    /* get linnum program size; currently we count the items and assume avg size is 2 */
    for( curr = SymTables[TAB_SEG].head, count = 0; curr; curr = curr->next ) {
        if ( curr->e.seginfo->LinnumQueue ) {
            struct line_num_info *lni;
            lni = (struct line_num_info *)((struct qdesc *)curr->e.seginfo->LinnumQueue)->head;
            for( ; lni; count++, lni = lni->next );
        }
    }
    seg_linenum->e.seginfo->CodeBuffer = LclAlloc( 0x200 + count * 2 );
    p = (struct dwarf_stmt_header32 *)seg_linenum->e.seginfo->CodeBuffer;
    p->version = 2;
    p->minimum_instruction_length = 1;
    p->default_is_stmt = 1;
    p->line_base = DWLINE_BASE;
    p->line_range = DWLINE_RANGE;
    p->opcode_base = DWLINE_OPCODE_BASE;
    px = (unsigned char *)&p->stdopcode_lengths;
    /* standard opcodes lengths (number of LEB operands) */
    memcpy( px, stdopsparms, DWLINE_OPCODE_BASE - 1 );
    px += DWLINE_OPCODE_BASE - 1;
    *px++ = 0; /* include directories sequence */
    /* file entries sequence (entry consists of name and 3 LEBs (dir idx, time, size))
     * if multiple file entries are to be supported, allocation size above has to be adjusted!
     */
    strcpy( (char *)px, ModuleInfo.g.FNames[0].fname );
    px += strlen( (char *)px ) + 1;
    *px++ = 0; /* dir idx */
    *px++ = 0; /* time */
    *px++ = 0; /* size */
    *px++ = 0; /* file entries end marker */
    p->header_length = px - (unsigned char *)&p->header_length - 4;

    /* now generate the line number "program" */
    for( curr = SymTables[TAB_SEG].head; curr; curr = curr->next ) {
        if ( curr->e.seginfo->LinnumQueue ) {
            struct line_num_info *lni;
            struct line_num_info *next;
            lni = (struct line_num_info *)((struct qdesc *)curr->e.seginfo->LinnumQueue)->head;

            /* create "set address" extended opcode with fixup */
            *px++ = 0;
            if ( ModuleInfo.defOfssize == USE64 ) {
                *px++ = 1+8;
                *px++ = DW_LNE_set_address;
                fixup = FixupCreate( &curr->sym, FIX_OFF64, OPTJ_NONE );
                fixup->locofs = px - (unsigned char *)p;
                *(uint_64 *)px = lni->offset;
                store_fixup( fixup, seg_linenum, (int_32 *)px );
                px += 8;
            } else {
                *px++ = 1+4;
                *px++ = DW_LNE_set_address;
                fixup = FixupCreate( &curr->sym, FIX_OFF32, OPTJ_NONE );
                fixup->locofs = px - (unsigned char *)p;
                *(uint_32 *)px = lni->offset;
                store_fixup( fixup, seg_linenum, (int_32 *)px );
                px += 4;
            }

            px += dwarf_line_gen( lni->number - 1, lni->offset, px );
            for( ; lni; lni = lni->next ) {
                if ( lni->file != 0 ) continue; /* currently support 1 source file only */
                next = lni->next;
                if ( !next )
                    px += dwarf_line_gen( 1, curr->sym.max_offset - lni->offset, px );
                else if ( next->file != 0 ) continue;
                else
                    px += dwarf_line_gen( next->number - lni->number, next->offset - lni->offset, px );
            }
        }
    }
    *px++ = 0; *px++ = 1; *px++ = DW_LNE_end_sequence; /* 1. 00=extended opcode, 2. size=1, 3. opcode */
    p->unit_length = px - (unsigned char *)&p->unit_length - 4;
    seg_linenum->sym.max_offset = p->unit_length + 4;
    return;
}

void *dwarf_create_sections( struct module_info *modinfo )
/********************************************************/
{
    int i;
    struct dwarfobj *obj;

    obj = LclAlloc( sizeof (struct dwarfobj ) );
    for ( i = 0; i < NUM_DWSEGS; i++ ) {
        obj->dwarf_seg[i] = (struct dsym *)CreateIntSegment( dwarf_segnames[i], "DWARF", 0, modinfo->Ofssize, FALSE );
    }
    dwarf_set_info( obj, obj->dwarf_seg[DWINFO_IDX] );
    dwarf_set_abbrev( obj, obj->dwarf_seg[DWABBREV_IDX] );
    dwarf_set_line( obj, obj->dwarf_seg[DWLINE_IDX] );
    return obj;
}
#endif
