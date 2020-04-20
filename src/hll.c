/****************************************************************************
*
*  This code is Public Domain.
*
*  ========================================================================
*
* Description:  implements hll directives:
*               .IF, .WHILE, .REPEAT, .ELSE, .ELSEIF, .ENDIF,
*               .ENDW, .UNTIL, .UNTILCXZ, .BREAK, .CONTINUE.
*               also handles C operators:
*               ==, !=, >=, <=, >, <, &&, ||, &, !,
*               and flags:
*               ZERO?, CARRY?, SIGN?, PARITY?, OVERFLOW?
*
****************************************************************************/

#include <ctype.h>

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "equate.h"
#include "label.h"
#include "expreval.h"
#include "types.h"
#include "hll.h"
#include "segment.h"
#include "listing.h"
#include "lqueue.h"
#include "myassert.h"

#define LABELSIZE 8
#define LABELSGLOBAL 0 /* make the generated labels global */
#define JMPPREFIX      /* define spaces before "jmp" or "loop" */
#define LABELFMT "@C%04X"

/* v2.10: static variables moved to ModuleInfo */
#define HllStack ModuleInfo.g.HllStack
#define HllFree  ModuleInfo.g.HllFree

#if LABELSGLOBAL
#define LABELQUAL "::"
#else
#define LABELQUAL ":"
#endif

#ifdef DEBUG_OUT
#define EOLCHAR '^'  /* this allows better displays */
#define EOLSTR  "^"
#else
#define EOLCHAR '\n' /* line termination char in generated source */
#define EOLSTR  "\n"
#endif

/* values for struct hll_item.cmd */
enum hll_cmd {
    HLL_IF,
    HLL_WHILE,
    HLL_REPEAT,
    HLL_BREAK  /* .IF behind .BREAK or .CONTINUE */
};

/* index values for struct hll_item.labels[] */
enum hll_label_index {
    LTEST,      /* test (loop) condition */
    LEXIT,      /* block exit            */
    LSTART,     /* loop start            */
};

/* values for struct hll_item.flags */
enum hll_flags {
    HLLF_ELSEOCCURED = 0x01,
};


/* item for .IF, .WHILE, .REPEAT, ... */
struct hll_item {
    struct hll_item     *next;
    uint_32             labels[3];      /* labels for LTEST, LEXIT, LSTART */
    char                *condlines;     /* .WHILE-blocks only: lines to add after 'test' label */
    enum hll_cmd        cmd;            /* start cmd (IF, WHILE, REPEAT) */
    enum hll_flags      flags;          /* v2.08: added */
    uint_32             truelabel;      /* v2.08: new member */
    uint_32             deflabel;       /* v2.13: default, replaces ilabel argument, is one of labels[3] */
    uint_32             falselabel;     /* v2.08: new member */
};

enum hll_op {
    HLLO_NONE,
    HLLO_OR,
    HLLO_AND
};

/* v2.08: struct added */
struct hll_opnd {
    enum  hll_op op; /* v2.13: added */
    char *lastjmp;
};

static ret_code GetExpression( struct hll_item *hll, int *i, struct asm_tok[], bool is_true, char *buffer, struct hll_opnd * );

/* c binary ops.
 * Order of items COP_EQ - COP_LE  and COP_ZERO - COP_OVERFLOW
 * must not be changed.
 */
enum c_bop {
    COP_NONE,
    COP_EQ,   /* == */
    COP_NE,   /* != */
    COP_GT,   /* >  */
    COP_LT,   /* <  */
    COP_GE,   /* >= */
    COP_LE,   /* <= */
    COP_AND,  /* && */
    COP_OR,   /* || */
    COP_ANDB, /* &  */
    COP_NEG,  /* !  */
    COP_ZERO, /* ZERO?   not really a valid C operator */
    COP_CARRY,/* CARRY?  not really a valid C operator */
    COP_SIGN, /* SIGN?   not really a valid C operator */
    COP_PARITY,  /* PARITY?   not really a valid C operator */
    COP_OVERFLOW /* OVERFLOW? not really a valid C operator */
};

/* items in table below must match order COP_ZERO - COP_OVERFLOW */
static const char flaginstr[] = { 'z',  'c',  's',  'p',  'o' };

/* items in tables below must match order COP_EQ - COP_LE */
static const char unsigned_cjmptype[] = {  'z',  'z',  'a',  'b',  'b', 'a' };
static const char signed_cjmptype[]   = {  'z',  'z',  'g',  'l',  'l', 'g' };
static const char neg_cjmptype[]      = {   0,    1,    0,    0,    1,   1  };

/* in Masm, there's a nesting level limit of 20. In JWasm, there's
 * currently no limit.
 */

#ifdef DEBUG_OUT
static unsigned evallvl;
static unsigned cntAlloc;  /* # of allocated hll_items */
static unsigned cntReused; /* # of reused hll_items */
static unsigned cntCond;   /* # of allocated 'condlines'-buffer in .WHILE-blocks */
static unsigned cntCondBytes; /* total size of allocated 'condlines'-buffers */
#endif

static uint_32 GetHllLabel( void )
/********************************/
{
    return ( ++ModuleInfo.hll_label );
}

/* get a C binary operator from the token stream.
 * there is a problem with the '<' because it is a "string delimiter"
 * which Tokenize() usually is to remove.
 * There has been a hack implemented in Tokenize() so that it won't touch the
 * '<' if .IF, .ELSEIF, .WHILE, .UNTIL, .UNTILCXZ or .BREAK/.CONTINUE has been
 * detected.
 */

#define CHARS_EQ  '=' + ( '=' << 8 )
#define CHARS_NE  '!' + ( '=' << 8 )
#define CHARS_GE  '>' + ( '=' << 8 )
#define CHARS_LE  '<' + ( '=' << 8 )
#define CHARS_AND '&' + ( '&' << 8 )
#define CHARS_OR  '|' + ( '|' << 8 )

static enum c_bop GetCOp( struct asm_tok *item )
/**********************************************/
{
    int size;
    enum c_bop rc;
    char *p = item->string_ptr;

    size = ( item->token == T_STRING ? item->stringlen : 0 );

    if ( size == 2 ) {
        switch ( *(uint_16 *)p ) {
        case CHARS_EQ:  rc = COP_EQ;  break;
        case CHARS_NE:  rc = COP_NE;  break;
        case CHARS_GE:  rc = COP_GE;  break;
        case CHARS_LE:  rc = COP_LE;  break;
        case CHARS_AND: rc = COP_AND; break;
        case CHARS_OR:  rc = COP_OR;  break;
        default: return( COP_NONE );
        }
    } else if ( size == 1 ) {
        switch ( *p ) {
        case '>': rc = COP_GT;   break;
        case '<': rc = COP_LT;   break;
        case '&': rc = COP_ANDB; break;
        case '!': rc = COP_NEG;  break;
        default: return( COP_NONE );
        }
    } else {
        if ( item->token != T_ID )
            return( COP_NONE );
        /* a valid "flag" string must end with a question mark */
        size = strlen( p );
        if ( *(p+size-1) != '?' )
            return( COP_NONE );
        if ( size == 5 && ( 0 == _memicmp( p, "ZERO", 4 ) ) )
            rc = COP_ZERO;
        else if ( size == 6 && ( 0 == _memicmp( p, "CARRY", 5 ) ) )
            rc = COP_CARRY;
        else if ( size == 5 && ( 0 == _memicmp( p, "SIGN", 4 ) ) )
            rc = COP_SIGN;
        else if ( size == 7 && ( 0 == _memicmp( p, "PARITY", 6 ) ) )
            rc = COP_PARITY;
        else if ( size == 9 && ( 0 == _memicmp( p, "OVERFLOW", 8 ) ) )
            rc = COP_OVERFLOW;
        else
            return( COP_NONE );
    }
    return( rc );
}

/* render an instruction */

static char *RenderInstr( char *dst, const char *instr, int start1, int end1, int start2, int end2, struct asm_tok tokenarray[] )
/*******************************************************************************************************************************/
{
    int i;
#ifdef DEBUG_OUT
    char *old = dst;
#endif
    i = strlen( instr );
    /* copy the instruction */
    memcpy( dst, instr, i );
    dst += i;
    /* copy the first operand's tokens */
    *dst++ = ' ';
    i = tokenarray[end1].tokpos - tokenarray[start1].tokpos;
    memcpy( dst, tokenarray[start1].tokpos, i );
    dst += i;
    if ( start2 != EMPTY ) {
        *dst++ = ',';
        /* copy the second operand's tokens */
        *dst++ = ' ';
        i = tokenarray[end2].tokpos - tokenarray[start2].tokpos;
        memcpy( dst, tokenarray[start2].tokpos, i );
        dst += i;
    } else if ( end2 != EMPTY ) {
        dst += sprintf( dst, ", %d", end2 );
    }
    *dst++ = EOLCHAR;
    *dst = NULLC;
    DebugMsg1(("%u RenderInstr(%s)=>%s<\n", evallvl, instr, old ));
    return( dst );
}

static char *GetLabelStr( int_32 label, char *buff )
/**************************************************/
{
    sprintf( buff, LABELFMT, label );
    return( buff );
}

/* render a Jcc instruction */

static char *RenderJcc( char *dst, char cc, int neg, uint_32 label )
/******************************************************************/
{
#ifdef DEBUG_OUT
    char *old = dst;
#endif
    /* create the jump opcode: j[n]cc */
    *dst++ = 'j';
    if ( neg )
        *dst++ = 'n';
    *dst++ = cc;
    if ( neg == FALSE )
        *dst++ = ' '; /* make sure there's room for the inverse jmp */

    *dst++ = ' ';
    GetLabelStr( label, dst );
    dst += strlen( dst );
    *dst++ = EOLCHAR;
    *dst = NULLC;
    DebugMsg1(("%u RenderJcc()=>%s<\n", evallvl, old ));
    return( dst );
}

/* a "token" in a C expression actually is an assembly expression */

static ret_code GetToken( struct hll_item *hll, int *i, struct asm_tok tokenarray[], struct expr *opnd )
/******************************************************************************************************/
{
    int end_tok;

    /* scan for the next C operator in the token array.
     * because the ASM evaluator may report an error if such a thing
     * is found ( CARRY?, ZERO? and alikes will be regarded as - not yet defined - labels )
     */
    for ( end_tok = *i; end_tok < Token_Count; end_tok++ ) {
        if ( ( GetCOp( &tokenarray[end_tok] ) ) != COP_NONE )
            break;
    }
    if ( end_tok == *i ) {
        opnd->kind = EXPR_EMPTY;
        return( NOT_ERROR );
    }
    if ( ERROR == EvalOperand( i, tokenarray, end_tok, opnd, 0 ) )
        return( ERROR );

    /* v2.11: emit error 'syntax error in control flow directive'.
     * May happen for expressions like ".if 1 + CARRY?"
     */
    if ( *i > end_tok ) {
        return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
    }

    return( NOT_ERROR );
}

/* a "simple" expression is
 * 1. two tokens, coupled with a <cmp> operator: == != >= <= > <
 * 2. two tokens, coupled with a "&" operator
 * 3. unary operator "!" + one token
 * 4. one token (short form for "<token> != 0")
 */
static ret_code GetSimpleExpression( struct hll_item *hll, int *i, struct asm_tok tokenarray[], bool is_true, char *buffer, struct hll_opnd *hllop )
/**************************************************************************************************************************************************/
{
    enum c_bop op;
    char instr;
    int op1_pos;
    int op1_end;
    int op2_pos;
    int op2_end;
    char *p;
    struct expr op1;
    struct expr op2;
    uint_32 label;

    DebugMsg1(("%u GetSimpleExpression(>%.32s< buf=>%s<) enter\n", evallvl, tokenarray[*i].tokpos, buffer ));

    while ( tokenarray[*i].string_ptr[0] == '!' && tokenarray[*i].string_ptr[1] == '\0' ) {
        (*i)++; //GetCOp( i );
        is_true = 1 - is_true;
    }

    /* the problem with '()' is that is might enclose just a standard Masm
     * expression or a "hll" expression. The first case is to be handled 
     * entirely by the expression evaluator, while the latter case is to be
     * handled HERE!
     */
    if ( tokenarray[*i].token == T_OP_BRACKET ) {
        int brcnt;
        int j;
        for ( brcnt = 1, j = *i + 1; tokenarray[j].token != T_FINAL; j++ ) {
            if ( tokenarray[j].token == T_OP_BRACKET )
                brcnt++;
            else if ( tokenarray[j].token == T_CL_BRACKET ) {
                brcnt--;
                if ( brcnt == 0 ) /* a standard Masm expression? */
                    break;
            } else if ( ( GetCOp( &tokenarray[j] )) != COP_NONE )
                break;
        }
        if ( brcnt ) {
            (*i)++;
            DebugMsg1(("%u GetSimpleExpression: calling GetExpression, i=%u\n", evallvl, *i));
            if ( ERROR == GetExpression( hll, i, tokenarray, is_true, buffer, hllop ) )
                return( ERROR );

            if ( tokenarray[*i].token != T_CL_BRACKET ) {
                //if (( tokenarray[*i].token == T_FINAL ) || ( tokenarray[*i].token == T_CL_BRACKET ))
                DebugMsg(( "GetSimpleExpression: expected ')', found: %s\n", tokenarray[*i].string_ptr ));
                return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
            }
            (*i)++;
            return( NOT_ERROR );
        }
    }

    /* get (first) operand */
    op1_pos = *i;
    if ( ERROR == GetToken( hll, i, tokenarray, &op1 ) )
        return ( ERROR );
    op1_end = *i;

    op = GetCOp( &tokenarray[*i] ); /* get operator */

    /* lower precedence operator ( && or || ) detected? */
    if ( op == COP_AND || op == COP_OR ) {
        /* v2.11: next 2 lines removed - && and || operators need a valid first operand */
        //if ( op1.kind == EXPR_EMPTY )
        //    return( NOT_ERROR );
        op = COP_NONE;
    } else if ( op != COP_NONE )
        (*i)++;

    label = hll->deflabel;

    DebugMsg1(("%u GetSimpleExpression: EvalOperand ok, kind=%X, i=%u [%s]\n", evallvl, op1.kind, *i, tokenarray[*i].tokpos ));

    /* check for special operators with implicite operand:
     * COP_ZERO, COP_CARRY, COP_SIGN, COP_PARITY, COP_OVERFLOW
     */
    if ( op >= COP_ZERO ) {
        if ( op1.kind != EXPR_EMPTY ) {
            DebugMsg(( "GetSimpleExpression: non-empty expression rejected: %s\n", tokenarray[op1_pos].tokpos ));
            return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
        }
        p = buffer;
        hllop->lastjmp = p;
        RenderJcc( p, flaginstr[ op - COP_ZERO ], !is_true, label );
        return( NOT_ERROR );
    }

    switch ( op1.kind ) {
    case EXPR_EMPTY:
        DebugMsg(( "GetSimpleExpression: empty expression rejected\n" ));
        return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) ); /* v2.09: changed from NOT_ERROR to ERROR */
    case EXPR_FLOAT:
        DebugMsg(( "GetSimpleExpression: float expression rejected: %s\n", tokenarray[op1_pos].tokpos ));
        return( EmitError( REAL_OR_BCD_NUMBER_NOT_ALLOWED ) ); /* v2.10: added */
    }

    if ( op == COP_NONE ) {
        switch ( op1.kind ) {
        case EXPR_REG:
            if ( op1.indirect == FALSE ) {
                p = RenderInstr( buffer, "and", op1_pos, op1_end, op1_pos, op1_end, tokenarray );
                hllop->lastjmp = p;
                RenderJcc( p, 'z', is_true, label );
                break;
            }
            /* no break */
        case EXPR_ADDR:
            p = RenderInstr( buffer, "cmp", op1_pos, op1_end, EMPTY, 0, tokenarray );
            hllop->lastjmp = p;
            RenderJcc( p, 'z', is_true, label );
            break;
        case EXPR_CONST:
#if 0
            /* v2.05: string constant is allowed! */
            if ( op1.string != NULL ) {
                return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
            }
#endif
            /* v2.11: error if constant doesn't fit in 32-bits */
            if ( op1.hvalue != 0 && op1.hvalue != -1 )
                return( EmitConstError( &op1 ) );

            hllop->lastjmp = buffer;

            if ( ( is_true == TRUE && op1.value ) ||
                ( is_true == FALSE && op1.value == 0 ) ) {
                sprintf( buffer, "jmp " LABELFMT EOLSTR, label );
                DebugMsg1(("%u GetSimpleExpression: jmp created >%s<\n", evallvl, buffer ));
            } else {
                //strcpy( buffer, " " EOLSTR ); /* v2.11: obsolete */
                *buffer = NULLC;
                DebugMsg1(("%u GetSimpleExpression: nullc created\n", evallvl ));
            }
            break;
#ifdef DEBUG_OUT
        default: /**/myassert( 0 ); break;
#endif
        }
        return( NOT_ERROR );
    }

    /* get second operand for binary operator */
    op2_pos = *i;
    if ( ERROR == GetToken( hll, i, tokenarray, &op2 ) ) {
        return( ERROR );
    }
    DebugMsg1(("%u GetSimpleExpression: EvalOperand 2 ok, type=%X, i=%u [%s]\n", evallvl, op2.type, *i, tokenarray[*i].tokpos));
    if ( op2.kind != EXPR_CONST && op2.kind != EXPR_ADDR && op2.kind != EXPR_REG ) {
        DebugMsg(("GetSimpleExpression: syntax error, op2.kind=%u\n", op2.kind ));
        return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
    }
    op2_end = *i;

    /* now generate ASM code for expression */

    if ( op == COP_ANDB ) {
        p = RenderInstr( buffer, "test", op1_pos, op1_end, op2_pos, op2_end, tokenarray );
        hllop->lastjmp = p;
        RenderJcc( p, 'e', is_true, label );
    } else if ( op <= COP_LE ) { /* ==, !=, >, <, >= or <= operator */
        /*
         * optimisation: generate 'or EAX,EAX' instead of 'cmp EAX,0'.
         * v2.11: use op2.value64 instead of op2.value
         */
        if ( Options.masm_compat_gencode &&
            ( op == COP_EQ || op == COP_NE ) &&
            op1.kind == EXPR_REG && op1.indirect == FALSE &&
            op2.kind == EXPR_CONST && op2.value64 == 0 ) {
            p = RenderInstr( buffer, "or", op1_pos, op1_end, op1_pos, op1_end, tokenarray );
        } else {
            p = RenderInstr( buffer, "cmp", op1_pos, op1_end, op2_pos, op2_end, tokenarray );
        }

        instr = ( ( IS_SIGNED( op1.mem_type ) || IS_SIGNED( op2.mem_type ) ) ? signed_cjmptype[op - COP_EQ] : unsigned_cjmptype[op - COP_EQ] );
        hllop->lastjmp = p;
        RenderJcc( p, instr, neg_cjmptype[op - COP_EQ] ? is_true : !is_true, label );
    } else {
        DebugMsg(("GetSimpleExpression: unexpected operator %s\n", tokenarray[op1_pos].tokpos ));
        return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
    }
    return( NOT_ERROR );
}

/* invert a Jump:
 * - Jx  -> JNx (x = e|z|c|s|p|o )
 * - JNx -> Jx  (x = e|z|c|s|p|o )
 * - Ja  -> Jbe, Jae -> Jb
 * - Jb  -> Jae, Jbe -> Ja
 * - Jg  -> Jle, Jge -> Jl
 * - Jl  -> Jge, Jle -> Jg
 * added in v2.11:
 * - jmp -> 0
 * - 0   -> jmp
 */
static void InvertJump( char *p )
/*******************************/
{
    if ( *p == NULLC ) { /* v2.11: convert 0 to "jmp" */
        strcpy( p, "jmp " );
        return;
    }

    p++;
    if ( *p == 'e' || *p == 'z' || *p == 'c' || *p == 's' || *p == 'p' || *p == 'o' ) {
        *(p+1) = *p;
        *p = 'n';
        return;
    } else if ( *p == 'n' ) {
        *p = *(p+1);
        *(p+1) = ' ';
        return;
    } else if ( *p == 'a' ) {
        *p++ = 'b';
    } else if ( *p == 'b' ) {
        *p++ = 'a';
    } else if ( *p == 'g' ) {
        *p++ = 'l';
    } else if ( *p == 'l' ) {
        *p++ = 'g';
    } else {
        /* v2.11: convert "jmp" to 0 */
        if ( *p == 'm' ) {
            p--;
            *p = NULLC;
        }
        return;
    }
    if ( *p == 'e' )
        *p = ' ';
    else
        *p = 'e';
    return;
}

/* Replace a label in the source lines generated so far.
 * todo: if more than 0xFFFF labels are needed,
 * it may happen that length of nlabel > length of olabel!
 * then the simple memcpy() below won't work!
 */

static bool ReplaceLabel( char *p, uint_32 olabel, uint_32 nlabel )
/*****************************************************************/
{
    char oldlbl[16];
    char newlbl[16];
    int i;
    bool ret = FALSE;

    GetLabelStr( olabel, oldlbl );
    GetLabelStr( nlabel, newlbl );

    i = strlen( newlbl );

    DebugMsg1(("%u ReplaceLabel(%s->%s, >%s<)\n", evallvl, oldlbl, newlbl, p ));
    while ( p = strstr( p, oldlbl ) ) {
        memcpy( p, newlbl, i );
        p += i;
        ret = TRUE;
    }
    return( ret );
}

/* operator &&, which has the second lowest precedence, is handled here */

static ret_code GetAndExpression( struct hll_item *hll, int *i, struct asm_tok tokenarray[], bool is_true, char *buffer, struct hll_opnd *hllop )
/***********************************************************************************************************************************************/
{
    char *ptr = buffer;
    char opfound = FALSE;

    DebugMsg1(("%u GetAndExpression(>%.32s< buf=>%s<) enter, truelabel=%u\n", evallvl, tokenarray[*i].tokpos, buffer, hll->truelabel ));

    if ( ERROR == GetSimpleExpression( hll, i, tokenarray, is_true, ptr, hllop ) )
        return( ERROR );
    while ( COP_AND == GetCOp( &tokenarray[*i] ) ) {

        struct hll_opnd hllop2 = {HLLO_NONE,NULL};
        char buff[16];

        (*i)++;
        DebugMsg1(("%u GetAndExpression: &&-operator found, is_true=%u, lastjmp=%s, truelabel=%u\n",
            evallvl, is_true, hllop->lastjmp ? hllop->lastjmp : "NULL", hll->truelabel ));

        if ( hllop->op == HLLO_OR ) {
            ptr = buffer+strlen( buffer );
            if (!hll->truelabel) hll->truelabel = GetHllLabel();
            GetLabelStr( hll->truelabel, ptr );
            strcat( ptr, LABELQUAL EOLSTR );
            DebugMsg1(("%u GetAndExpression: label appended >%s<, truelabel=%u\n", evallvl, ptr, hll->truelabel ));
            if (is_true) /* todo: explain why this is needed for &&, but not for || */
                ReplaceLabel( buffer, hll->deflabel, hll->truelabel );
            hllop->op = HLLO_NONE;
            hll->truelabel = 0;
        }
        if ( is_true ) {
            if ( hllop->lastjmp ) {
                /* the last jmp has to be inverted and the label modified */
                char *p = hllop->lastjmp;
                InvertJump( p );           /* step 1 */
                if ( hll->falselabel == 0 ) {/* step 2 */
                    hll->falselabel = GetHllLabel();
                    opfound = TRUE;
                }
                if ( *p ) {               /* v2.11: there might be a 0 at lastjmp */
                    p += 4;               /* skip 'jcc ' or 'jmp ' */
                    /* v2.13: don't skip a label that might be behind lastjmp */
                    //GetLabelStr( hllop->truelabel, p );
                    //strcat( p, EOLSTR );
                    GetLabelStr( hll->falselabel, buff );
                    DebugMsg1(("%u GetAndExpression: lastjmp to be changed: >%s< ->%s\n", evallvl, hllop->lastjmp, buff ));
                    strcat( buff, EOLSTR );
                    if (*p)
                        memcpy( p, buff, strlen(buff) );
                    else
                        strcpy( p, buff );
                }
                /* v2.13 removed */
                //ReplaceLabel( buffer, hll->deflabel, hll->truelabel );
                DebugMsg1(("%u GetAndExpression: falselabel=%u, buffer >%s<\n", evallvl, hll->falselabel, buffer ));
                hllop->lastjmp = NULL;
                //opfound = TRUE;
            }
        }

        ptr += strlen( ptr );
        if ( ERROR == GetSimpleExpression( hll, i, tokenarray, is_true, ptr, &hllop2 ) )
            return( ERROR );
        memcpy( hllop, &hllop2, sizeof(hllop2) );
    };
    if (opfound)
        hllop->op = HLLO_AND;
    DebugMsg1(("%u GetAndExpression: exit, truelabel=%u, opfound=%u\n", evallvl, hll->truelabel, opfound ));
    return( NOT_ERROR );
}

/* operator ||, which has the lowest precedence, is handled here */

static ret_code GetExpression( struct hll_item *hll, int *i, struct asm_tok tokenarray[], bool is_true, char *buffer, struct hll_opnd *hllop )
/********************************************************************************************************************************************/
{
    char *ptr = buffer;
    uint_32 truelabel = 0;
    char opfound = FALSE;

    DebugMsg1(("%u GetExpression(>%.32s< is_true=%u buf=>%s<) enter\n", ++evallvl, tokenarray[*i].tokpos, is_true, buffer ));

    /* v2.08: structure changed from for(;;) to while() to increase
     * readability and - optionally - handle the second operand differently
     * than the first.
     */

    if ( ERROR == GetAndExpression( hll, i, tokenarray, is_true, ptr, hllop ) ) {
        DebugMsg1(("%u GetExpression exit, error\n", evallvl-- ));
        return( ERROR );
    }
    while ( COP_OR == GetCOp( &tokenarray[*i] ) ) {

        uint_32 nlabel;
        uint_32 olabel;
        struct hll_opnd hllop2 = {HLLO_NONE,NULL};
        char buff[16];

        /* what's done inside the loop:
         1. check if the preceding expression needs a "terminating" label ( hllop->op != HLLO_NONE )
            if so, create the label (truelabel)
         2. create a (new) truelabel
         3. if is_true == FALSE, the last Jcc target must be inverted and the label replaced
         4. get the next expression
         */

        (*i)++;
        DebugMsg1(("%u GetExpression: ||-operator found, is_true=%u, lastjmp=%s, truelabel=%u\n", evallvl, is_true, hllop->lastjmp ? hllop->lastjmp : "NULL", hll->truelabel ));

        if ( hllop->op == HLLO_AND ) {
            ptr = buffer+strlen( buffer );
            GetLabelStr( hll->falselabel, ptr );
            strcat( ptr, LABELQUAL EOLSTR );
            DebugMsg1(("%u GetExpression: label appended >%s<, falselabel=%u\n", evallvl, ptr, hll->falselabel ));
            //ReplaceLabel( buffer, hll->deflabel, hll->truelabel );
            hllop->op = HLLO_NONE;
            hll->falselabel = 0;
        }
        opfound = TRUE;
        if ( truelabel == 0 ) {
            truelabel = GetHllLabel();
            DebugMsg1(("%u GetExpression: new truelabel=%u\n", evallvl, truelabel ));
        }
        if ( is_true == FALSE ) {
            if ( hllop->lastjmp ) {
                char *p = hllop->lastjmp;
                InvertJump( p );
                if ( *p ) { /* v2.11: there might be a 0 at lastjmp */
                    p += 4;                /* skip 'jcc ' or 'jmp ' */
                    GetLabelStr( truelabel, p );
                    strcat( p, EOLSTR );
                }
                DebugMsg1(("%u GetExpression: jmp inverted(%s), truelabel=%u\n", evallvl, hllop->lastjmp, truelabel ));

                nlabel = GetHllLabel();
                olabel = hll->deflabel;
                if ( ReplaceLabel( buffer, olabel, nlabel )) {
                    sprintf( ptr + strlen( ptr ), "%s" LABELQUAL EOLSTR, GetLabelStr( nlabel, buff ) );
                    DebugMsg1(("%u GetExpression: dest changed, label added >%s<\n", evallvl, ptr ));
                } else
                    ModuleInfo.hll_label--;

                hllop->lastjmp = NULL;
            }
        }
        ptr += strlen( ptr );
        if ( ERROR == GetAndExpression( hll, i, tokenarray, is_true, ptr, &hllop2 ) ) {
            DebugMsg1(("%u GetExpression exit, error\n", evallvl-- ));
            return( ERROR );
        }
        memcpy( hllop, &hllop2, sizeof(hllop2) );
    }
    if (opfound) {
        hllop->op = HLLO_OR;
        DebugMsg1(("%u GetExpression, HLLO_OR set, truelabels=%u/%u\n", evallvl, truelabel, hll->truelabel ));
        if ( truelabel )
            if ( hll->truelabel )
                ReplaceLabel( buffer, truelabel, hll->truelabel );
            else
                hll->truelabel = truelabel;
    }
    DebugMsg1(("%u GetExpression exit, truelabel=%u, opfound=%u >%.32s<\n", evallvl--, hll->truelabel, opfound, tokenarray[*i].tokpos ));
    return( NOT_ERROR );
}

/*
 * write assembly test lines to line queue.
 * v2.11: local line buffer removed; src pointer has become a parameter.
 */

static ret_code QueueTestLines( char *src )
/*****************************************/
{
    char *start;

    DebugMsg1(("QueueTestLines(\"%s\") enter\n", src ? src : "NULL" ));
    while ( src ) {
        //if (*src == ' ') src++; /* v2.11: obsolete */
        start = src;
        if ( src = strchr( src, EOLCHAR ) )
            *src++ = NULLC;
        if ( *start )
            AddLineQueue( start );
    }

    DebugMsg1(("QueueTestLines exit\n"));
    return( NOT_ERROR );
}

/*
 * evaluate the C like boolean expression found in HLL structs
 * like .IF, .ELSEIF, .WHILE, .UNTIL and .UNTILCXZ
 * might return multiple lines (strings separated by EOLCHAR)
 * - i = index for tokenarray[] where expression starts. Is restricted
 *       to one source line (till T_FINAL)
 * - ilabel: label to jump to if expression is <is_true>!
 *
 *              is_true    label
 * ------------------------------------
 *   .IF:       FALSE      LTEST
 *   .ELSEIF:   FALSE      LTEST
 *   .WHILE:    TRUE       LSTART
 *   .UNTIL:    FALSE      LSTART
 *   .UNTILCXZ: FALSE      LSTART
 *   .BREAK .IF:TRUE       LEXIT
 *   .CONT .IF: TRUE       LSTART/LTEST (.while/.repeat)
 */

static ret_code EvaluateHllExpression( struct hll_item *hll, int *i, struct asm_tok tokenarray[], int ilabel, bool is_true, char *buffer )
/****************************************************************************************************************************************/
{
    struct hll_opnd hllop = {HLLO_NONE,NULL};
    char *ptr;

    hll->deflabel = hll->labels[ilabel];
    DebugMsg1(("EvaluateHllExpression enter, deflabel=%u, is_true=%u\n", hll->deflabel, is_true ));
    hll->truelabel = 0;
    hll->falselabel = 0;

    *buffer = NULLC;
    if ( ERROR == GetExpression( hll, i, tokenarray, is_true, buffer, &hllop ) )
        return( ERROR );
    /* v2.11: changed */
    //if ( *buffer == EOLCHAR ) {
        //DebugMsg(( "EvaluateHllExpression: EOL at pos 0 in line buffer\n" ));
    if ( tokenarray[*i].token != T_FINAL ) {
        DebugMsg(( "EvaluateHllExpression: unexpected tokens >%s<\n", tokenarray[*i].tokpos ));
        return( EmitError( SYNTAX_ERROR_IN_CONTROL_FLOW_DIRECTIVE ) );
    }
    if ( hll->falselabel || hll->truelabel ) {
        ptr = buffer+strlen( buffer );
        GetLabelStr( hll->falselabel ? hll->falselabel : hll->truelabel, ptr );
        strcat( ptr, LABELQUAL EOLSTR );
        DebugMsg1(("EvaluateHllExpression: label appended >%s<, labels=%u/%u\n", ptr, hll->falselabel, hll->truelabel ));
    }
    return( NOT_ERROR );
}

/* for .UNTILCXZ: check if expression is simple enough.
 * what's acceptable is ONE condition, and just operators == and !=
 * Constants (0 or != 0) are also accepted.
 */

static ret_code CheckCXZLines( char *p )
/**************************************/
{
    int lines = 0;
    int i;
    int addchars;
    char *px;
    bool NL = TRUE;

    DebugMsg1(("CheckCXZLines enter, p=>%s<\n", p ));
    /* syntax ".untilcxz 1" has a problem: there's no "jmp" generated at all.
     * if this syntax is to be supported, activate the #if below.
     */
    for (; *p; p++ ) {
        if ( *p == EOLCHAR ) {
            NL = TRUE;
            lines++;
        } else if ( NL ) {
            NL = FALSE;
            if ( *p == 'j' ) {
                p++;
                /* v2.06: rewritten */
                if ( *p == 'm' && lines == 0 ) {
                    addchars = 2; /* make room for 2 chars, to replace "jmp" by "loope" */
                    px = "loope";
                } else if ( lines == 1 && ( *p == 'z' || (*p == 'n' && *(p+1) == 'z') ) ) {
                    addchars = 3; /* make room for 3 chars, to replace "jz"/"jnz" by "loopz"/"loopnz" */
                    px = "loop";
                } else
                    return( ERROR ); /* anything else is "too complex" */
            //replace_instr:
                for ( p--, i = strlen( p ); i >= 0; i-- ) {
                    *(p+addchars+i) = *(p+i);
                }
                memcpy( p, px, strlen( px ) );
            }
#if 0 /* handle ".untilcxz 1" like masm does */
            else if ( *p == ' ' && *(p+1) == EOLCHAR && lines == 0 ) {
                p++;
                GetLabelStr( hll->labels[LSTART], p );
                strcat( p, EOLSTR );
                addchars = 5;
                px = "loope";
                goto replace_instr;
            }
#endif
        }
    }
    if ( lines > 2 )
        return( ERROR );
    return( NOT_ERROR );
}

/* .IF, .WHILE or .REPEAT directive */

ret_code HllStartDir( int i, struct asm_tok tokenarray[] )
/********************************************************/
{
    struct hll_item      *hll;
    ret_code             rc = NOT_ERROR;
    int                  cmd = tokenarray[i].tokval;
    char buff[16];
    char buffer[MAX_LINE_LEN*2];

    DebugMsg1(("HllStartDir(%s) enter\n", tokenarray[i].string_ptr ));

    i++; /* skip directive */

    /* v2.06: is there an item on the free stack? */
    if ( HllFree ) {
        hll = HllFree;
        DebugCmd( cntReused++ );
    } else {
        hll = LclAlloc( sizeof( struct hll_item ) );
        DebugCmd( cntAlloc++ );
    }

    /* structure for .IF .ELSE .ENDIF
     *    cond jump to LTEST-label
     *    ...
     *    jmp LEXIT
     *  LTEST:
     *    ...
     *  LEXIT:

     * structure for .IF .ELSEIF
     *    cond jump to LTEST
     *    ...
     *    jmp LEXIT
     *  LTEST:
     *    cond jump to (new) LTEST
     *    ...
     *    jmp LEXIT
     *  LTEST:
     *    ...

     * structure for .WHILE and .REPEAT:
     *   jmp LTEST (for .WHILE only)
     * LSTART:
     *   ...
     * LTEST: (jumped to by .continue)
     *   a) test end condition, cond jump to LSTART label
     *   b) unconditional jump to LSTART label
     * LEXIT: (jumped to by .BREAK)
     */

    hll->labels[LEXIT] = 0;

    switch ( cmd ) {
    case T_DOT_IF:
        hll->labels[LSTART] = 0; /* not used by .IF */
        hll->labels[LTEST] = GetHllLabel();
        hll->cmd = HLL_IF;
        hll->flags = 0;
        /* get the C-style expression, convert to ASM code lines */
        rc = EvaluateHllExpression( hll, &i, tokenarray, LTEST, FALSE, buffer );
        if ( rc == NOT_ERROR ) {
            QueueTestLines( buffer );
            /* if no lines have been created, the LTEST label isn't needed */
            //if ( !is_linequeue_populated() ) {
            if ( buffer[0] == NULLC ) {
                hll->labels[LTEST] = 0;
            }
        }
        break;
    case T_DOT_WHILE:
    case T_DOT_REPEAT:
        /* create the label to start of loop */
        hll->labels[LSTART] = GetHllLabel();
        hll->labels[LTEST] = 0; /* v2.11: test label is created only if needed */
        //hll->labels[LEXIT] = GetHllLabel(); /* v2.11: LEXIT is only needed for .BREAK */
        if ( cmd == T_DOT_WHILE ) {
            hll->cmd = HLL_WHILE;
            hll->condlines = NULL;
            if ( tokenarray[i].token != T_FINAL ) {
                rc = EvaluateHllExpression( hll, &i, tokenarray, LSTART, TRUE, buffer );
                if ( rc == NOT_ERROR ) {
                    int size;
                    size = strlen( buffer ) + 1;
                    hll->condlines = LclAlloc( size );
                    memcpy( hll->condlines, buffer, size );
                    DebugCmd( cntCond++ ); DebugCmd( cntCondBytes += size );
                }
            } else
                buffer[0] = NULLC;  /* just ".while" without expression is accepted */

            /* create a jump to test label */
            /* optimisation: if line at 'test' label is just a jump, dont create label and don't jump! */
            if ( _memicmp( buffer, "jmp", 3 ) ) {
                hll->labels[LTEST] = GetHllLabel();
                AddLineQueueX( JMPPREFIX "jmp %s", GetLabelStr( hll->labels[LTEST], buff ) );
            }
        } else {
            hll->cmd = HLL_REPEAT;
        }
        AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LSTART], buff ) );
        break;
#ifdef DEBUG_OUT
    default: /**/myassert( 0 ); break;
#endif
    }

    if ( tokenarray[i].token != T_FINAL && rc == NOT_ERROR ) {
        DebugMsg(("HllStartDir: unexpected token [%s]\n", tokenarray[i].tokpos ));
        EmitErr( SYNTAX_ERROR_EX, tokenarray[i].tokpos );
        rc = ERROR;
        //return( ERROR ); /* v2.08: continue and parse the line queue */
    }
    /* v2.06: remove the item from the free stack */
    if ( hll == HllFree )
        HllFree = hll->next;
    hll->next = HllStack;
    HllStack = hll;

    if ( ModuleInfo.list )
        LstWrite( LSTTYPE_DIRECTIVE, GetCurrOffset(), NULL );

    if ( is_linequeue_populated() ) /* might be NULL! (".if 1") */
        RunLineQueue();

    return( rc );
}

/*
 * .ENDIF, .ENDW, .UNTIL and .UNTILCXZ directives.
 * These directives end a .IF, .WHILE or .REPEAT block.
 */
ret_code HllEndDir( int i, struct asm_tok tokenarray[] )
/******************************************************/
{
    //struct asym       *sym;
    struct hll_item     *hll;
    ret_code            rc = NOT_ERROR;
    int                 cmd = tokenarray[i].tokval;
    char buff[16];
    char buffer[MAX_LINE_LEN*2];

    DebugMsg1(("HllEndDir(%s) enter\n", tokenarray[i].string_ptr ));

    if ( HllStack == NULL ) {
        DebugMsg(("HllEndDir: hll stack is empty\n"));
        return( EmitError( DIRECTIVE_MUST_BE_IN_CONTROL_BLOCK ) );
    }

    hll = HllStack;
    HllStack = hll->next;
    /* v2.06: move the item to the free stack */
    hll->next = HllFree;
    HllFree = hll;

    switch ( cmd ) {
    case T_DOT_ENDIF:
        if ( hll->cmd != HLL_IF ) {
            DebugMsg(("HllEndDir: no .IF on the hll stack\n"));
            return( EmitErr( BLOCK_NESTING_ERROR, tokenarray[i].string_ptr ) );
        }
        i++;
        /* if a test label isn't created yet, create it */
        if ( hll->labels[LTEST] ) {
            AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LTEST], buff ) );
        }
        break;
    case T_DOT_ENDW:
        if ( hll->cmd != HLL_WHILE ) {
            DebugMsg(("HllEndDir: no .WHILE on the hll stack\n"));
            return( EmitErr( BLOCK_NESTING_ERROR, tokenarray[i].string_ptr ) );
        }
        i++;
        /* create test label */
        if ( hll->labels[LTEST] ) {
            AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LTEST], buff ) );
        }
        QueueTestLines( hll->condlines );
        LclFree( hll->condlines );
        break;
    case T_DOT_UNTILCXZ:
        if ( hll->cmd != HLL_REPEAT ) {
            DebugMsg(("HllEndDir: no .REPEAT on the hll stack\n"));
            return( EmitErr( BLOCK_NESTING_ERROR, tokenarray[i].string_ptr ) );
        }
        i++;
        if ( hll->labels[LTEST] ) /* v2.11: LTEST only needed if .CONTINUE has occured */
            AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LTEST], buff ) );

        /* read in optional (simple) expression */
        if ( tokenarray[i].token != T_FINAL ) {
            rc = EvaluateHllExpression( hll, &i, tokenarray, LSTART, FALSE, buffer );
            if ( rc == NOT_ERROR ) {
                rc = CheckCXZLines( buffer );
                if ( rc == NOT_ERROR )
                    QueueTestLines( buffer ); /* write condition lines */
                else
                    EmitError( EXPR_TOO_COMPLEX_FOR_UNTILCXZ );
            }
        } else {
            AddLineQueueX( JMPPREFIX "loop %s", GetLabelStr( hll->labels[LSTART], buff ) );
        }
        break;
    case T_DOT_UNTIL:
        if ( hll->cmd != HLL_REPEAT ) {
            DebugMsg(("HllEndDir: no .REPEAT on the hll stack\n"));
            return( EmitErr( BLOCK_NESTING_ERROR, tokenarray[i].string_ptr ) );
        }
        i++;
        if ( hll->labels[LTEST] ) /* v2.11: LTEST only needed if .CONTINUE has occured */
            AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LTEST], buff ) );

        /* read in (optional) expression */
        /* if expression is missing, just generate nothing */
        if ( tokenarray[i].token != T_FINAL ) {
            rc = EvaluateHllExpression( hll, &i, tokenarray, LSTART, FALSE, buffer );
            if ( rc == NOT_ERROR )
                QueueTestLines( buffer ); /* write condition lines */
        }
        break;
#ifdef DEBUG_OUT
    default: /**/myassert( 0 ); break;
#endif
    }

    /* create the exit label if it has been referenced */
    if ( hll->labels[LEXIT] )
        AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LEXIT], buff ) );

    if ( tokenarray[i].token != T_FINAL && rc == NOT_ERROR ) {
        EmitErr( SYNTAX_ERROR_EX, tokenarray[i].tokpos );
        rc = ERROR;
    }
    if ( ModuleInfo.list )
        LstWrite( LSTTYPE_DIRECTIVE, GetCurrOffset(), NULL );

    /* v2.11: always run line-queue if it's not empty. */
    if ( is_linequeue_populated() )
        RunLineQueue();

    return( rc );
}

/*
 * .ELSE, .ELSEIF, .CONTINUE and .BREAK directives.
 * .ELSE, .ELSEIF:
 *    - create a jump to exit label
 *    - render test label if it was referenced
 *    - for .ELSEIF, create new test label and evaluate expression
 * .CONTINUE, .BREAK:
 *    - jump to test / exit label of innermost .WHILE/.REPEAT block
 *
 */
ret_code HllExitDir( int i, struct asm_tok tokenarray[] )
/*******************************************************/
{
    //int               level;
    //struct asym       *sym;
    struct hll_item     *hll;
    ret_code            rc = NOT_ERROR;
    int                 idx;
    int                 cmd = tokenarray[i].tokval;
    char buff[16];
    char buffer[MAX_LINE_LEN*2];

    DebugMsg1(("HllExitDir(%s) enter\n", tokenarray[i].string_ptr ));

    hll = HllStack;

    if ( hll == NULL ) {
        DebugMsg(("HllExitDir stack error\n"));
        return( EmitError( DIRECTIVE_MUST_BE_IN_CONTROL_BLOCK ) );
    }

    switch ( cmd ) {
    case T_DOT_ELSE:
    case T_DOT_ELSEIF:
        if ( hll->cmd != HLL_IF ) {
            DebugMsg(("HllExitDir(%s): labels[LTEST]=%X\n", tokenarray[i].string_ptr, hll->labels[LTEST]));
            return( EmitErr( BLOCK_NESTING_ERROR, tokenarray[i].string_ptr ) );
        }
        /* v2.08: check for multiple ELSE clauses */
        if ( hll->flags & HLLF_ELSEOCCURED ) {
            return( EmitError( DOT_ELSE_CLAUSE_ALREADY_OCCURED_IN_THIS_DOT_IF_BLOCK ) );
        }

        /* the 'exit'-label is only needed if an .ELSE branch exists.
         * That's why it is created delayed.
         */
        if ( hll->labels[LEXIT] == 0 )
            hll->labels[LEXIT] = GetHllLabel();
        AddLineQueueX( JMPPREFIX "jmp %s", GetLabelStr( hll->labels[LEXIT], buff ) );

        if ( hll->labels[LTEST] > 0 ) {
            AddLineQueueX( "%s" LABELQUAL, GetLabelStr( hll->labels[LTEST], buff ) );
            hll->labels[LTEST] = 0;
        }
        i++;
        if ( cmd == T_DOT_ELSEIF ) {
            /* create new labels[LTEST] label */
            hll->labels[LTEST] = GetHllLabel();
            rc = EvaluateHllExpression( hll, &i, tokenarray, LTEST, FALSE, buffer );
            if ( rc == NOT_ERROR )
                QueueTestLines( buffer );
        } else
            hll->flags |= HLLF_ELSEOCCURED;

        break;
    case T_DOT_BREAK:
    case T_DOT_CONTINUE:
        for ( ; hll && hll->cmd == HLL_IF; hll = hll->next );
        if ( hll == NULL ) {
            return( EmitError( DIRECTIVE_MUST_BE_IN_CONTROL_BLOCK ) );
        }
        /* v2.11: create 'exit' and 'test' labels delayed.
         */
        if ( cmd == T_DOT_BREAK ) {
            if ( hll->labels[LEXIT] == 0 )
                hll->labels[LEXIT] = GetHllLabel();
            idx = LEXIT;
        } else {
            /* 'test' is not created for .WHILE loops here; because
             * if it doesn't exist, there's no condition to test.
             */
            if ( hll->cmd == HLL_REPEAT && hll->labels[LTEST] == 0 )
                hll->labels[LTEST] = GetHllLabel();
            idx = ( hll->labels[LTEST] ? LTEST : LSTART );
        }

        /* .BREAK .IF ... or .CONTINUE .IF ? */
        i++;
        if ( tokenarray[i].token != T_FINAL ) {
            if ( tokenarray[i].token == T_DIRECTIVE && tokenarray[i].tokval == T_DOT_IF ) {
                enum hll_cmd savedcmd = hll->cmd;
                hll->cmd = HLL_BREAK;
                i++;
                /* v2.11: set rc and don't exit if an error occurs; see hll3.aso */
                rc = EvaluateHllExpression( hll, &i, tokenarray, idx, TRUE, buffer );
                if ( rc == NOT_ERROR )
                    QueueTestLines( buffer );
                hll->cmd = savedcmd;
            }
        } else {
            AddLineQueueX( JMPPREFIX "jmp %s", GetLabelStr( hll->labels[idx], buff ) );
        }
        break;
#ifdef DEBUG_OUT
    default: /**/myassert( 0 ); break;
#endif
    }
    if ( tokenarray[i].token != T_FINAL && rc == NOT_ERROR ) {
        EmitErr( SYNTAX_ERROR_EX, tokenarray[i].tokpos );
        rc = ERROR;
    }

    if ( ModuleInfo.list )
        LstWrite( LSTTYPE_DIRECTIVE, GetCurrOffset(), NULL );

    /* v2.11: always run line-queue if it's not empty. */
    if ( is_linequeue_populated() )
        RunLineQueue();

    return( rc );
}

/* check if an hll block has been left open. called after pass 1 */

void HllCheckOpen( void )
/***********************/
{
    if ( HllStack ) {
        //EmitErr( BLOCK_NESTING_ERROR, ".if-.repeat-.while" );
        EmitErr( UNMATCHED_BLOCK_NESTING, ".if-.repeat-.while" );
    }
    DebugMsg(("HllCheckOpen: allocated items:%u, reused items:%u, .while cond-blocks/bytes:%u/%u\n", cntAlloc, cntReused, cntCond, cntCondBytes ));
}

#if FASTMEM==0
void HllFini( void )
/******************/
{
    struct hll_item *curr;
    struct hll_item *next;
    /* release the items in the HllFree heap.
     * there might also be some left in HllStack...
     */
    for ( curr = HllFree; curr; curr = next ) {
        next = curr->next;
        LclFree( curr );
    }
}
#endif

/* HllInit() is called for each pass */

void HllInit( int pass )
/**********************/
{
    //if ( pass == PASS_1 )
    //    HllFree = NULL;

    //HllStack = NULL; /* empty stack of open hll directives */
    ModuleInfo.hll_label = 0; /* init hll label counter */
#ifdef DEBUG_OUT
    evallvl = 0;
    if ( pass == PASS_1 ) {
        cntAlloc = 0;
        cntReused = 0;
        cntCond = 0;
        cntCondBytes = 0;
    }
#endif
    return;
}
