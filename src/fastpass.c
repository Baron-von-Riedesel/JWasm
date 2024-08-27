/****************************************************************************
*
*  This code is Public Domain.
*
*  ========================================================================
*
* Description:  implements the "fastpass" handling.
*               "fastpass" is an optimization which increases
*               assembly time speed by storing preprocessed lines
*               in memory during the first pass. In further passes,
*               those lines are "read" instead of the original assembly
*               source files.
*               Speed increase is significant if there's a large include
*               file at the top of an assembly source which contains
*               just equates and type definitions, because there's no need
*               to save such lines during pass one.
*
****************************************************************************/

#include <ctype.h>

#include "globals.h"
#include "memalloc.h"
#include "parser.h"
#include "input.h"
#include "segment.h"
#include "fastpass.h"
#include "listing.h"

#include "myassert.h"

#if FASTPASS

/* rework listing for v2.19.
 * goal: remove current restrictions and bugs:
 * - trashed listing if code bytes increase AFTER pass 1 so that a second line becomes necessary.
 * - multiple lines for data possible.
 * For this to be achieved, the listing isn't written after SaveState() has
 * been called. Instead a queue is generated in pass 1, that holds the listing lines.
 * In further passes, those items may be extended if necessary.
 * The listing is written AFTER the last pass has run.
 */

/* equ_item: used for a linked list of assembly time variables. Any variable
 * which is defined or modified after SaveState() has been called is to be stored
 * here - once!
 */
struct equ_item {
    struct equ_item *next;
    struct asym *sym;
    int lvalue;
    int hvalue;
    enum memtype mem_type; /* v2.07: added */
    bool isdefined;
};

/* mod_state: store the module state within SaveState() */

struct mod_state {
    bool init;           /* is this struct initialized? */
    struct {
        struct equ_item *head; /* the list of modified assembly time variables */
        struct equ_item *tail;
    } Equ;
    unsigned saved_src; /* v2.13: save the current src item */
    uint_8 modinfo[ sizeof( struct module_info ) - sizeof( struct module_vars ) ];
};

static struct mod_state modstate; /* struct to store assembly status */

static struct {
    struct line_item *head;
    struct line_item *tail;
} LineStore;
struct line_item *LineStoreCurr; /* must be global! */

/* v2.19: listing queue */
static struct {
    struct list_item *head;
    struct list_item *tail;
} ListStore;
static struct list_item *ListStoreCurr;

bool StoreState;
bool UseSavedState;
static bool ReqSavedState; /* v2.19 */

/*
 * save the current status (happens in pass one only) and
 * switch to "save precompiled lines" mode.
 * the status is then restored in further passes,
 * and the precompiled lines are used for assembly then.
 */

static void SaveState( void )
/***************************/
{
    DebugMsg1(("SaveState enter\n" ));
    StoreState = TRUE;
    /* v2.19: UseSavedState is now set in DefSavedState(), so it's always
     * zero during pass one.
     */
    //UseSavedState = TRUE;
    modstate.init = TRUE;
    modstate.Equ.head = modstate.Equ.tail = NULL;

    /* v2.13: save the current source file */
    modstate.saved_src = get_curr_srcfile();
    /* save the part of ModuleInfo that is NOT in module_vars */
    memcpy( &modstate.modinfo, (uint_8 *)&ModuleInfo + sizeof( struct module_vars ), sizeof( modstate.modinfo ) );

    ListStore.head = ListStore.tail = NULL;

    SegmentSaveState();
    AssumeSaveState();
    ContextSaveState(); /* save pushcontext/popcontext stack */

    DebugMsg1(( "SaveState exit\n" ));
}

/* flags: b0: 1=store line with comment
 * v2.19: flags obsolete.
 */

//void StoreLine( const char *srcline, int flags )
void StoreLine( const char *srcline )
/***********************************/
{
    //int i,j;
    int i;
    char *p;

#ifdef DEBUG_OUT
    if ( Options.nofastpass )
        return;
#endif
    if ( ModuleInfo.GeneratedCode ) /* don't store generated lines! */
        return;
    if ( StoreState == FALSE ) /* line store already started? */
        SaveState();

    i = strlen( srcline );
	/* v2.19: storing comment no longer needed */
	//j = ( ( ( flags & FSL_WITHCMT ) && ModuleInfo.CurrComment ) ? strlen( ModuleInfo.CurrComment ) : 0 );
    //LineStoreCurr = LclAlloc( i + j + sizeof( struct line_item ) );
    LineStoreCurr = LclAlloc( i + sizeof( struct line_item ) );
    LineStoreCurr->next = NULL;
    LineStoreCurr->lineno = GetLineNumber();
    LineStoreCurr->pList = NULL; /* v2.19 */
    if ( MacroLevel ) {
        LineStoreCurr->srcfile = 0xfff;
    } else {
        LineStoreCurr->srcfile = get_curr_srcfile();
    }
	/* v2.19: storing comment no longer needed */
    //if ( j ) {
    //    memcpy( LineStoreCurr->line, srcline, i );
    //    memcpy( LineStoreCurr->line + i, ModuleInfo.CurrComment, j + 1 );
    //} else
        memcpy( LineStoreCurr->line, srcline, i + 1 );

    DebugMsg1(("StoreLine(>%s<): cur=%X\n", LineStoreCurr->line, LineStoreCurr ));

    /* v2.08: don't store % operator at pos 0 */
    for ( p = LineStoreCurr->line; *p && isspace(*p); p++ );
    if (*p == '%' && ( _memicmp( p+1, "OUT", 3 ) || is_valid_id_char( *(p+4) ) ) )
        *p = ' ';

#ifdef DEBUG_OUT
    if ( Options.print_linestore )
        printf("%s\n", LineStoreCurr->line );
#endif
    if ( LineStore.head )
        LineStore.tail->next = LineStoreCurr;
    else
        LineStore.head = LineStoreCurr;
    LineStore.tail = LineStoreCurr;
}

/* called by PassOneChecks().
 * Set the default state, may be altered by calling SkipSavedState().
 */

void DefSavedState( void )
/*************************/
{
    UseSavedState = ( StoreState && ReqSavedState );
    StoreState = FALSE;
}
/* an error has been detected in pass one. it should be
 reported in pass 2, so ensure that a full source scan is done then
 */

void SkipSavedState( void )
/*************************/
{
    DebugMsg(("SkipSavedState called\n"));
    ReqSavedState = FALSE;
}

/* for FASTPASS, just pass 1 is a full pass, the other passes
 don't start from scratch and they just assemble the preprocessed
 source. To be able to restart the assembly process from a certain
 location within the source, it's necessary to save the value of
 assembly time variables.
 However, to reduce the number of variables that are saved, an
 assembly-time variable is only saved when
 - it is changed
 - it was defined when StoreState() is called
 */

void SaveVariableState( struct asym *sym )
/****************************************/
{
    struct equ_item *p;

    DebugMsg1(( "SaveVariableState(%s)=%d\n", sym->name, sym->value ));
    sym->issaved = TRUE; /* don't try to save this symbol (anymore) */
    p = LclAlloc( sizeof( struct equ_item ) );
    p->next = NULL;
    p->sym = sym;
    p->lvalue    = sym->value;
    p->hvalue    = sym->value3264; /* v2.05: added */
    p->mem_type  = sym->mem_type;  /* v2.07: added */
    p->isdefined = sym->isdefined;
    if ( modstate.Equ.tail ) {
        modstate.Equ.tail->next = p;
        modstate.Equ.tail = p;
    } else {
        modstate.Equ.head = modstate.Equ.tail = p;
    }
//    printf("state of symbol >%s< saved, value=%u, defined=%u\n", sym->name, sym->value, sym->defined);
}

/* called by OnePass() if UseSavedState == true;
 * returns start of line store */

struct line_item *RestoreState( void )
/************************************/
{
    DebugMsg1(("RestoreState enter\n"));
    if ( modstate.init ) {
        struct equ_item *curr;
        /* restore values of assembly time variables */
        for ( curr = modstate.Equ.head; curr; curr = curr->next ) {
            DebugMsg1(("RestoreState: sym >%s<, value=%Xh (hvalue=%Xh), defined=%u\n", curr->sym->name, curr->lvalue, curr->hvalue, curr->isdefined ));
            /* v2.07: MT_ABS is obsolete */
            //if ( curr->sym->mem_type == MT_ABS ) {
                curr->sym->value     = curr->lvalue;
                curr->sym->value3264 = curr->hvalue;
                curr->sym->mem_type  = curr->mem_type; /* v2.07: added */
                curr->sym->isdefined = curr->isdefined;
            //}
        }
        /* fields in module_vars are not to be restored.
         * v2.10: the module_vars fields are not saved either.
         */
        //memcpy( &modstate.modinfo.g, &ModuleInfo.g, sizeof( ModuleInfo.g ) );
        memcpy( (char *)&ModuleInfo + sizeof( struct module_vars ), &modstate.modinfo, sizeof( modstate.modinfo ) );
        /* v2.13: restore the current source file */
        set_curr_srcfile( modstate.saved_src, 0 );
        SetOfssize();
        SymSetCmpFunc();
    }

	ListStoreCurr = NULL;

    return( LineStore.head );
}

/* v2.19: listing reworked */
/* ListGetItem() - called by LstWrite() if UseSavedState == 1 */

struct list_item *ListGetItem( uint_8 bGeneratedCode )
/****************************************************/
{
	if ( bGeneratedCode ) {
		ListStoreCurr = ListStoreCurr->next;
    } else {
        ListStoreCurr = LineStoreCurr->pList;
#ifdef DEBUG_OUT
        if (!ListStoreCurr) DebugMsg1(("ListGetItem: ListStoreCurr==NULL, Line=%s [%p]\n", LineStoreCurr->line, LineStoreCurr ));
        /**/myassert( ListStoreCurr);
#endif
    }

	return ListStoreCurr;
}

/* ListNextGenCode() - if generated code that is to be displayed BEFORE
 * the line ( PROC prologues, SEH data in 64-bit ).
 * Implementation is a bit hackish.
 */
void ListNextGenCode( void )
/**************************/
{
	/* scan for first "generated code" line in list store */
	for ( ; ListStoreCurr->next; ListStoreCurr = ListStoreCurr->next ) {
		if ( strlen( ListStoreCurr->next->line ) > 28 && ListStoreCurr->next->line[28] == '*' )
			break;
	}
}

/* ListAddItem() - called by LstWrite() if StoreState == 1 (that's in pass 1 only) */

struct list_item *ListAddItem( char *pLine )
/******************************************/
{
	int len = strlen( pLine );
	struct list_item *pItem;

	pItem = LclAlloc( sizeof( struct list_item ) + len );
	pItem->next = NULL;
	pItem->lprfx = NULL;
	memcpy( pItem->line, pLine, len+1 );

	if ( ListStore.head )
		ListStore.tail->next = pItem;
	else
		ListStore.head = pItem;
	ListStore.tail = pItem;

    /* attach to the current line if it's still NULL */
	if ( !LineStoreCurr->pList )
		LineStoreCurr->pList = pItem;

	return pItem;
}

/* update list item - just the first 28 bytes.
 * The 28 comes from listing.c: sizeof (struct lstleft.buffer - 4)
 */

void ListUpdateItem( struct list_item *pItem, char *pLine )
/*********************************************************/
{
    memcpy( pItem->line, pLine, 28 );
}

/* ListAddSubItem(), called by
 * a) LstWrite()           if StoreState == 1
 * b) ListUpdateSubItem()  if UseSavedState == 1
 */
void ListAddSubItem( struct list_item *pItem, char *pLine )
/*********************************************************/
{
	int len = strlen( pLine );
	struct lprefix *curr;
	struct lprefix *prefix;
	prefix = LclAlloc( sizeof( struct lprefix ) + ( len > 28 ? len : 28 ) );
	prefix->next = NULL;
	memcpy( prefix->line, pLine, len+1 );
	if ( pItem->lprfx == NULL )
		pItem->lprfx = prefix;
	else {
		for ( curr = pItem->lprfx; curr->next; curr = curr->next );
		curr->next = prefix;
	}
	return;
}

/* called by LstWrite() if UseSavedState == 1 */

void ListUpdateSubItem( struct list_item *pItem, int prefix, char *pLine )
/************************************************************************/
{
	struct lprefix *curr;
	for ( curr = pItem->lprfx; prefix && curr; prefix--, curr = curr->next );
	if ( curr )
		memcpy( curr->line, pLine, strlen( pLine ) );
	else
		ListAddSubItem( pItem, pLine );
}

/* last pass is done, write listing from list queue items. */

void ListFlushAll( void )
/***********************/
{
	struct list_item *pItem = ListStore.head;
	for (; pItem; pItem = pItem->next ) {
		struct lprefix *pPrefix;
		LstPrintf("%s\n", pItem->line );
		for ( pPrefix = pItem->lprfx; pPrefix; pPrefix = pPrefix->next )
			LstPrintf("%s\n", pPrefix->line );
	}
}

#if FASTMEM==0
/* this is debugging code only. Usually FASTPASS and FASTMEM
 * are both either TRUE or FALSE.
 * It's active if both DEBUG and TRMEM is set in Makefile.
 */
void FreeLineStore( void )
/************************/
{
    struct line_item *next;
    for ( LineStoreCurr = LineStore.head; LineStoreCurr; ) {
        next = LineStoreCurr->next;
        LclFree( LineStoreCurr );
        LineStoreCurr = next;
    }
}
#endif

/* called by AssembleInit() once per module. */

void FastpassInit( void )
/***********************/
{
    StoreState = FALSE;
    modstate.init = FALSE;
    LineStore.head = NULL;
    LineStore.tail = NULL;
    UseSavedState = FALSE;
    ReqSavedState = TRUE;
}

#endif
