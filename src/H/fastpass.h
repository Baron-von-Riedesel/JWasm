
/* this is Public Domain.
 fastpass.h defines structures and externals which are needed by the
 "fast pass" feature. This feature speeds JWasm's assembly significantly
 if huge header files containing declarations and definitions are used
 (as it is the case with WinInc and Masm32), since the header files are
 then scanned in pass one only.
 */

#if FASTPASS

struct lprefix {
	struct lprefix *next;
	char line[1];
};

struct list_item {
	struct list_item *next;
	struct lprefix *lprfx;
	char line[1];
};

/* line_item: used for a linked list of preprocessed lines. After SaveState()
 * has been called, all preprocessed lines are written in pass one and read
 * in further passes
 */

struct line_item {
    struct line_item *next;
    uint_32 lineno:20, srcfile:12;
    struct list_item *pList;
    char line[1];
};

extern struct line_item *LineStoreCurr;

/* source lines start to be "stored" when one of the following is detected:
 * - an instruction
 * - a data item (but not a struct field)
 * - directives which "generate source": PROC, INVOKE, .IF, .WHILE, .REPEAT
 * - directives ALIGN and ORG (which emit bytes and/or change $)
 * - directive END (to ensure that there is at least 1 line)
 * - directive ASSUME if operand is a forward reference
 */

//extern struct mod_state modstate;
extern bool StoreState; /* is 1 if states are to be stored in pass one */

/* UseSavedState: is TRUE if preprocessed lines are to be read in pass 2,3,...
 * Currently, this flag is set DURING pass one! That's bad,
 * because it means that the flag itself doesn't tell whether
 * (preprocessed) lines are read.
 * the fix proposal is: set the flag - conditionally - AFTER pass one.
 * Also, rename the flag (perhaps UseSavedLines )!
 */
extern bool UseSavedState; 

//void SaveState( void );
void FastpassInit( void );
void SegmentSaveState( void );
void AssumeSaveState( void );
void ContextSaveState( void );
void StoreLine( const char *, int );
void DefSavedState( void );
void SkipSavedState( void );
struct line_item *RestoreState( void );
void SaveVariableState( struct asym *sym );
void FreeLineStore( void );

struct list_item *ListAddItem( char *pLine );
struct list_item *ListGetItem( unsigned char bGeneratedCode );
void ListUpdateItem( struct list_item *pItem, char *pLine );
void ListAddPrefix( struct list_item *pItem, char *codebytes );
void ListUpdatePrefix( struct list_item *pItem, int, char *codebytes );
void ListWriteAll( void );

#define FStoreLine( flags ) if ( Parse_Pass == PASS_1 ) StoreLine( CurrSource, flags )

#define FSL_NOCMT   0
#define FSL_WITHCMT 1

#else

#define FStoreLine( flags )

#endif

