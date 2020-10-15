
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

/* integer definitions */

typedef unsigned char   uint_8;
typedef signed char     int_8;
typedef unsigned short  uint_16;
typedef signed short    int_16;
#if defined(LONG_IS_64BITS) || defined(__LP64__)
typedef unsigned int    uint_32;
typedef   signed int    int_32;
typedef unsigned long   uint_64;
typedef   signed long   int_64;
#else
typedef unsigned long      uint_32;
typedef   signed long      int_32;
#if defined(LLONG_MAX) || defined(__GNUC__)
typedef unsigned long long uint_64;
typedef   signed long long int_64;
#else
typedef unsigned __int64  uint_64;
#ifdef __OCC__
typedef          __int64  int_64;
#else
typedef   signed __int64  int_64;
#endif
#endif
#endif

/* PE definitions */

struct IMAGE_DOS_HEADER {
    uint_16 e_magic;          // Magic number
    uint_16 e_cblp;           // Bytes on last page of file
    uint_16 e_cp;             // Pages in file
    uint_16 e_crlc;           // Relocations
    uint_16 e_cparhdr;        // Size of header in paragraphs
    uint_16 e_minalloc;       // Minimum extra paragraphs needed
    uint_16 e_maxalloc;       // Maximum extra paragraphs needed
    uint_16 e_ss;             // Initial (relative) SS value
    uint_16 e_sp;             // Initial SP value
    uint_16 e_csum;           // Checksum
    uint_16 e_ip;             // Initial IP value
    uint_16 e_cs;             // Initial (relative) CS value
    uint_16 e_lfarlc;         // File address of relocation table
    uint_16 e_ovno;           // Overlay number
    uint_16 e_res[4];         // Reserved words
    uint_16 e_oemid;          // OEM identifier (for e_oeminfo)
    uint_16 e_oeminfo;        // OEM information; e_oemid specific
    uint_16 e_res2[10];       // Reserved words
    uint_32 e_lfanew;         // File address of new exe header
};

struct IMAGE_FILE_HEADER {
    uint_16 Machine;
    uint_16 NumberOfSections;
    uint_32 TimeDateStamp;
    uint_32 PointerToSymbolTable;
    uint_32 NumberOfSymbols;
    uint_16 SizeOfOptionalHeader;
    uint_16 Characteristics;
};

#define IMAGE_NUMBEROF_DIRECTORY_ENTRIES 16

struct IMAGE_DATA_DIRECTORY {
    uint_32 VirtualAddress;
    uint_32 Size;
};

#define IMAGE_DIRECTORY_ENTRY_EXPORT       0
#define IMAGE_DIRECTORY_ENTRY_IMPORT       1
#define IMAGE_DIRECTORY_ENTRY_RESOURCE     2
#define IMAGE_DIRECTORY_ENTRY_EXCEPTION    3
#define IMAGE_DIRECTORY_ENTRY_SECURITY     4
#define IMAGE_DIRECTORY_ENTRY_BASERELOC    5
#define IMAGE_DIRECTORY_ENTRY_DEBUG        6
#define IMAGE_DIRECTORY_ENTRY_ARCHITECTURE 7
#define IMAGE_DIRECTORY_ENTRY_GLOBALPTR    8
#define IMAGE_DIRECTORY_ENTRY_TLS          9
#define IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG  10
#define IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT 11
#define IMAGE_DIRECTORY_ENTRY_IAT          12

#define IMAGE_NT_OPTIONAL_HDR32_MAGIC      0x10b
#define IMAGE_NT_OPTIONAL_HDR64_MAGIC      0x20b

/* Subsystem values */
#define IMAGE_SUBSYSTEM_UNKNOWN              0   // Unknown subsystem.
#define IMAGE_SUBSYSTEM_NATIVE               1   // Image doesn't require a subsystem.
#define IMAGE_SUBSYSTEM_WINDOWS_GUI          2   // Image runs in the Windows GUI subsystem.
#define IMAGE_SUBSYSTEM_WINDOWS_CUI          3   // Image runs in the Windows character subsystem.
#define IMAGE_SUBSYSTEM_OS2_CUI              5   // image runs in the OS/2 character subsystem.
#define IMAGE_SUBSYSTEM_POSIX_CUI            7   // image runs in the Posix character subsystem.
#define IMAGE_SUBSYSTEM_NATIVE_WINDOWS       8   // image is a native Win9x driver.
#define IMAGE_SUBSYSTEM_WINDOWS_CE_GUI       9   // Image runs in the Windows CE subsystem.
#define IMAGE_SUBSYSTEM_EFI_APPLICATION      10  //
#define IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER  11
#define IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER   12  //
#define IMAGE_SUBSYSTEM_EFI_ROM              13
#define IMAGE_SUBSYSTEM_XBOX                 14

struct IMAGE_OPTIONAL_HEADER32 {

    uint_16 Magic;
    uint_8  MajorLinkerVersion;
    uint_8  MinorLinkerVersion;
    uint_32 SizeOfCode;
    uint_32 SizeOfInitializedData;
    uint_32 SizeOfUninitializedData;
    uint_32 AddressOfEntryPoint;
    uint_32 BaseOfCode;
    uint_32 BaseOfData;

    // NT additional fields.

    uint_32 ImageBase;
    uint_32 SectionAlignment;
    uint_32 FileAlignment;
    uint_16 MajorOperatingSystemVersion;
    uint_16 MinorOperatingSystemVersion;
    uint_16 MajorImageVersion;
    uint_16 MinorImageVersion;
    uint_16 MajorSubsystemVersion;
    uint_16 MinorSubsystemVersion;
    uint_32 Win32VersionValue;
    uint_32 SizeOfImage;
    uint_32 SizeOfHeaders;
    uint_32 CheckSum;
    uint_16 Subsystem;
    uint_16 DllCharacteristics;
    uint_32 SizeOfStackReserve;
    uint_32 SizeOfStackCommit;
    uint_32 SizeOfHeapReserve;
    uint_32 SizeOfHeapCommit;
    uint_32 LoaderFlags;
    uint_32 NumberOfRvaAndSizes;
    struct IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
};

struct IMAGE_PE_HEADER32 {
    uint_32 Signature;
    struct IMAGE_FILE_HEADER FileHeader;
    struct IMAGE_OPTIONAL_HEADER32 OptionalHeader;
};

struct IMAGE_OPTIONAL_HEADER64 {
    uint_16 Magic;
    uint_8  MajorLinkerVersion;
    uint_8  MinorLinkerVersion;
    uint_32 SizeOfCode;
    uint_32 SizeOfInitializedData;
    uint_32 SizeOfUninitializedData;
    uint_32 AddressOfEntryPoint;
    uint_32 BaseOfCode;
    uint_64 ImageBase;
    uint_32 SectionAlignment;
    uint_32 FileAlignment;
    uint_16 MajorOperatingSystemVersion;
    uint_16 MinorOperatingSystemVersion;
    uint_16 MajorImageVersion;
    uint_16 MinorImageVersion;
    uint_16 MajorSubsystemVersion;
    uint_16 MinorSubsystemVersion;
    uint_32 Win32VersionValue;
    uint_32 SizeOfImage;
    uint_32 SizeOfHeaders;
    uint_32 CheckSum;
    uint_16 Subsystem;
    uint_16 DllCharacteristics;
    uint_64 SizeOfStackReserve;
    uint_64 SizeOfStackCommit;
    uint_64 SizeOfHeapReserve;
    uint_64 SizeOfHeapCommit;
    uint_32 LoaderFlags;
    uint_32 NumberOfRvaAndSizes;
    struct IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
};

struct IMAGE_PE_HEADER64 {
    uint_32 Signature;
    struct IMAGE_FILE_HEADER FileHeader;
    struct IMAGE_OPTIONAL_HEADER64 OptionalHeader;
};

#define IMAGE_SIZEOF_SHORT_NAME 8

struct IMAGE_SECTION_HEADER {
    char Name[IMAGE_SIZEOF_SHORT_NAME];
    union {
        uint_32 PhysicalAddress;
        uint_32 VirtualSize;
    } Misc;
    uint_32 VirtualAddress;
    uint_32 SizeOfRawData;
    uint_32 PointerToRawData;
    uint_32 PointerToRelocations;
    uint_32 PointerToLinenumbers;
    uint_16 NumberOfRelocations;
    uint_16 NumberOfLinenumbers;
    uint_32 Characteristics;
};


#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif

#define VERBOSE 0

//--- compare two blocks

int compare( char *pBuff1, char *pBuff2, int size, char *file1, char *file2 ) {
    int cnt = 0;
    char *pStart = pBuff1;

    while ( size ) {

        for( ;size && *pBuff1 == *pBuff2; pBuff1++, pBuff2++, size-- );
        if ( size ) {
            cnt++;
            printf("%08Xh: %02X %02X (%s %s)\n", pBuff1 - pStart, *pBuff1, *pBuff2, file1, file2 );
            size--;
            pBuff1++;
            pBuff2++;
        }
    }
    return( cnt );
}

int faterr1( char *file) {
    printf("invalid PE binary: %s\n", file );
    return(1);
}
int faterr2() {
    printf("files don't have that many lines\n");
    return(1);
}

int main( int argc, char **argv)
{
    int  argidx = 1;
    FILE *fh;
    char *arg;
    char *file1;
    int filesize1;
    char *buffer1;
    unsigned int header1;
    char *file2;
    int filesize2;
    char *buffer2;
    unsigned int header2;
    unsigned int cnt;
    int dwLine;
    unsigned int dwFileOfs;
    unsigned int dwSections;
    unsigned int dwOfs;
    unsigned int dwExp;
    unsigned int dwHdrSize;
    char fPE;
    char fCoff;
    char fText;
    char cCurr;
    char *pBuff1;
    char *pBuff2;
    char *pTmp2;
    struct IMAGE_SECTION_HEADER *pSec;

    fPE = false;
    fCoff = false;
    fText = false;
    file1 = NULL;
    file2 = NULL;
/*--- scan cmdline */
    for ( ;argv[argidx]; argidx++ ) {
        arg = argv[argidx];
        cCurr = *arg;
        if ( cCurr == '-' || cCurr == '/' ) {
            arg++;
            if ( !strcmp( arg, "pe" ) )
                fPE = true;
            else if ( !strcmp( arg, "co" ) )
                fCoff = true;
            else if ( !strcmp( arg, "t" ) ) {
                fText = true;
                dwLine = -1;
            } else {
                printf("unknown option\n");
                return(1);
            }
        } else if ( fText == true && dwLine < 0 ) {
            dwLine = atoi( arg );
        } else if ( file1 == NULL ) {
            file1 = arg;
        } else if ( file2 == NULL ) {
            file2 = arg;
        } else {
            printf("too many arguments\n");
            return(1);
        }
    } /* endw */

    if ( file1 == NULL || file2 == NULL ) {
        printf("jfc v1.5, Public Domain.\n");
        printf("jfc compares two (binary) files.\n");
        printf("usage: jfc [-co|-pe|-t <n>] file1 file2\n");
        printf("   -co: files in coff format, ignore timestamps\n");
        printf("   -pe: files in PE format, ignore timestamps\n");
        printf("   -t: files are plain text, ignore first <n> lines\n");
        return(1);
    }

    cnt = 0;
    fh = fopen( file1, "rb" );
    if ( !fh ) {
        printf("open error file '%s' [%u]\n", file1, errno );
        return(1);
    }
    fseek( fh, 0, SEEK_END );
    filesize1 = ftell( fh );
    fseek( fh, 0, SEEK_SET );
    buffer1 = malloc( filesize1 );
    if ( !buffer1 ) {
        printf("out of memory\n");
        fclose( fh );
        return(1);
    }
    cnt = fread( buffer1, 1, filesize1, fh );
    fclose( fh );
    if ( cnt != filesize1 ) {
        printf("read error file '%s' [%u]\n", file1, errno );
        return(1);
    }

    fh = fopen( file2, "rb" );
    if ( !fh ) {
        printf("open error file '%s' [%u]\n", file2, errno );
        return(1);
    }
    fseek( fh, 0, SEEK_END );
    filesize2 = ftell( fh );
    fseek( fh, 0, SEEK_SET );
    buffer2 = malloc( filesize2 );
    if ( !buffer2 ) {
        printf("out of memory\n");
        fclose( fh );
        return(1);
    }
    cnt = fread( buffer2, 1, filesize2, fh );
    fclose( fh );
    if ( cnt != filesize2 ) {
        printf("read error file '%s' [%u]\n", file2, errno );
        return(1);
    }

    pBuff1 = buffer1;
    pBuff2 = buffer2;

//--- when comparing PE binaries,
//--- 1. skip the MZ header
//--- 2. compare the PE header separately (without time stamp)
//--- 3. compare the rest

    if ( fPE ) {
        dwFileOfs = ((struct IMAGE_DOS_HEADER *)pBuff1)->e_lfanew;
        if ( dwFileOfs > filesize1 )
            return( faterr1( file1 ) );
        pBuff1 += dwFileOfs;
        if ( *(uint_32 *)pBuff1 != 0x4550 ) // "PE"?
            return( faterr1( file1 ) );
        dwFileOfs = ((struct IMAGE_DOS_HEADER *)pBuff2)->e_lfanew;
        if ( dwFileOfs > filesize2 )
            return( faterr1( file2 ) );
        pBuff2 += dwFileOfs;
        if ( *(uint_32 *)pBuff2 != 0x4550 )
            return( faterr1( file2 ) );

        header1 = ((struct IMAGE_PE_HEADER32 *)pBuff1)->OptionalHeader.SizeOfHeaders;
        header2 = ((struct IMAGE_PE_HEADER32 *)pBuff2)->OptionalHeader.SizeOfHeaders;
        dwHdrSize = ((struct IMAGE_PE_HEADER32 *)pBuff1)->FileHeader.NumberOfSections * sizeof(struct IMAGE_SECTION_HEADER) +
            sizeof( struct IMAGE_PE_HEADER32 );
        ((struct IMAGE_PE_HEADER32 *)pBuff2)->FileHeader.TimeDateStamp = ((struct IMAGE_PE_HEADER32 *)pBuff1)->FileHeader.TimeDateStamp;

        /* compare headers */
#if VERBOSE
        printf("comparing headers\n" );
#endif
        cnt += compare( pBuff1, pBuff2, dwHdrSize, file1, file2 );

        /* v1.3: dont compare timestamp in export directory */

        do {
            /* index 0 = export directory */
            dwExp = ((struct IMAGE_PE_HEADER32 *)pBuff1)->OptionalHeader.DataDirectory[0].VirtualAddress;
            if (!dwExp)
                break;
            if ( dwExp != ((struct IMAGE_PE_HEADER32 *)pBuff2)->OptionalHeader.DataDirectory[0].VirtualAddress )
                break;
            dwSections = ((struct IMAGE_PE_HEADER32 *)pBuff1)->FileHeader.NumberOfSections;
            pSec = (struct IMAGE_SECTION_HEADER *)(pBuff1+sizeof( struct IMAGE_PE_HEADER32) );
            while ( dwSections ) {
                if ( dwExp >= pSec->VirtualAddress && dwExp < pSec->VirtualAddress + pSec->Misc.VirtualSize ) {
                    dwOfs = dwExp - pSec->VirtualAddress + pSec->PointerToRawData;
                    *(uint_32 *)(buffer2 + dwOfs + 4) = *(uint_32 *)(buffer1 + dwOfs + 4);   //offset 4 is expdir timestamp
                    break;
                }
                pSec++;
                dwSections--;
            }
        } while (0);
        /* now prepare to compare the section contents */
        pBuff1 = buffer1 + header1;
        if ( header1 >= filesize1 )
            return( faterr1( file1 ) );
        filesize1 -= header1;
        pBuff2 = buffer2 + header2;
        if ( header2 >= filesize2 )
            return( faterr1( file2 ) );
        filesize2 -= header2;
    } else if ( fCoff ) {

        ((struct IMAGE_FILE_HEADER *)pBuff2)->TimeDateStamp = ((struct IMAGE_FILE_HEADER *)pBuff1)->TimeDateStamp;

        /* todo: if codeview info is contained,
         * don't compare the compiler info.
         */

    } else if ( fText ) { /* v1.4: compare text files, optionally skipping <dwLine> lines */
        while( dwLine ) {
            if (!(pBuff1 = strchr( pBuff1, '\n' )))
                return( faterr2() );
            if (!(pBuff2 = strchr( pBuff2, '\n' )))
                return( faterr2() );
            dwLine--;
        };
        filesize1 = filesize1 - ( pBuff1 - buffer1 );
        filesize2 = filesize2 - ( pBuff2 - buffer2 );

        /* v1.5: translate CR+LF to LF for compare */

        pTmp2 = pBuff2;
        while ( filesize1 > 0 ) {
            char *pTmp = pBuff1;
            if ( *pBuff1 == 0xD && *(pBuff1+1) == 0xA )
                pBuff1++;
            if ( *pBuff2 == 0xD && *(pBuff2+1) == 0xA )
                pBuff2++;
            if ( *pBuff1 != *pBuff2 ) {
                printf("%08Xh: %02X %02X (%s %s)\n", pBuff1 - buffer1, *pBuff1, *pBuff2, file1, file2 );
                cnt++;
            }
            pBuff1++;
            pBuff2++;
            filesize1 -= pBuff1 - pTmp;
        }
        filesize2 -= pBuff2 - pTmp2;
        if ( filesize2 != filesize1 ) {
            printf("%s, %s: file sizes differ (%d %d)\n", file1, file2, filesize1, filesize2 );
            return(1);
        }

        return( cnt != 0);
    }

    if ( filesize1 != filesize2 ) {
        printf("%s, %s: file sizes differ\n", file1, file2 );
        return(1);
    }

#if VERBOSE
    printf("comparing contents\n" );
#endif
    cnt += compare( pBuff1, pBuff2, filesize1, file1, file2 );

    free( buffer1 );
    free( buffer2 );

    return( cnt != 0);
}
