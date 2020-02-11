
;--- a few definitions from ntdef

LIST_ENTRY STRUCT
Flink   DWORD ?
Blink   DWORD ?
LIST_ENTRY ENDS

PWSTR typedef ptr WORD

UNICODE_STRING STRUCT
Length_         WORD ?  ; size of string in bytes
MaximumLength   WORD ?  ; size of string buffer in bytes
Buffer          PWSTR ? ; string
UNICODE_STRING ENDS

LARGE_INTEGER union
struct
LowPart     DWORD ?
HighPart    SDWORD ?
ends
QuadPart    SQWORD ?
LARGE_INTEGER ends

BOOLEAN typedef BYTE

;--- a few definitions from ntddk

IO_NO_INCREMENT equ 0

FILE_DEVICE_UNKNOWN equ 22h

FILE_READ_ACCESS equ 1

METHOD_BUFFERED equ 0

DPFLTR_DEFAULT_ID equ 101
DPFLTR_INFO_LEVEL equ 3


DISPATCHER_HEADER STRUCT
Type_           BYTE ?
Absolute        BYTE ?
Size_           BYTE ?
Inserted        BYTE ?
SignalState     SDWORD ?
WaitListHead    LIST_ENTRY <>
DISPATCHER_HEADER ENDS

KEVENT STRUCT
Header DISPATCHER_HEADER <>
KEVENT ENDS
PKEVENT typedef PTR KEVENT

KDEVICE_QUEUE_ENTRY STRUCT 4
DeviceListEntry LIST_ENTRY <>
SortKey         DWORD ?
Inserted        BYTE ?
KDEVICE_QUEUE_ENTRY ENDS

IRP_MJ_CREATE           equ 0
IRP_MJ_CLOSE            equ 2
IRP_MJ_READ             equ 3
IRP_MJ_WRITE            equ 4
IRP_MJ_DEVICE_CONTROL   equ 0Eh
IRP_MJ_MAXIMUM_FUNCTION equ 1Bh

PVOID typedef ptr
PCHAR typedef ptr SBYTE
PFILE_OBJECT typedef ptr FILE_OBJECT

DRIVER_OBJECT STRUCT
Type_           SWORD ?
Size_           SWORD ?
DeviceObject    PVOID ?
Flags           DWORD ?
DriverStart     PVOID ?
DriverSize      DWORD ?
DriverSection   PVOID ?
DriverExtension PVOID ?
DriverName      UNICODE_STRING <>
HardwareDatabase PVOID ?
FastIoDispatch  PVOID ?
DriverInit      PVOID ?
DriverStartIo   PVOID ?
DriverUnload    PVOID ?
MajorFunction   PVOID (IRP_MJ_MAXIMUM_FUNCTION + 1) dup(?)
DRIVER_OBJECT ENDS

IO_STATUS_BLOCK STRUCT
Status      SDWORD ?
Information DWORD ?
IO_STATUS_BLOCK ENDS

PIO_STATUS_BLOCK typedef ptr IO_STATUS_BLOCK

KAPC STRUCT 4
Type_           SWORD ?
Size_           SWORD ?
Spare0          DWORD ?
Thread          PVOID ?
ApcListEntry    LIST_ENTRY <>
KernelRoutine   PVOID ?
RundownRoutine  PVOID ?
NormalRoutine   PVOID ?
NormalContext   PVOID ?
SystemArgument1 PVOID ?
SystemArgument2 PVOID ?
ApcStateIndex   BYTE ?
ApcMode         BYTE ?
Inserted        BYTE ?
KAPC ENDS

IRP_ STRUCT
Type_           WORD ?
Size_           WORD ?
MdlAddress          PVOID ?
Flags               DWORD ?
UNION AssociatedIrp
    MasterIrp       PVOID ?
    IrpCount        DWORD ?
    SystemBuffer    PVOID ?
ENDS
ThreadListEntry     LIST_ENTRY <>
IoStatus            IO_STATUS_BLOCK <>
RequestorMode       BYTE ?
PendingReturned     BYTE ?
StackCount          BYTE ?
CurrentLocation     BYTE ?
Cancel              BYTE ?
CancelIrql          BYTE ?
ApcEnvironment      BYTE ?
AllocationFlags     BYTE ?
UserIosb            PIO_STATUS_BLOCK ?
UserEvent           PKEVENT ?
UNION Overlay
    STRUCT AsynchronousParameters
        UserApcRoutine  PVOID ?
        UserApcContext  PVOID ?
    ENDS
    AllocationSize      LARGE_INTEGER <>
ENDS
CancelRoutine       PVOID ?
UserBuffer          PVOID ?
UNION Tail
    STRUCT Overlay
        UNION
            DeviceQueueEntry KDEVICE_QUEUE_ENTRY <>
            STRUCT
                DriverContext PVOID 4 dup(?)
            ENDS

        ENDS
        Thread              PVOID ?
        AuxiliaryBuffer     PCHAR ?
        STRUCT
            ListEntry       LIST_ENTRY <>
            UNION
                CurrentStackLocation PVOID ?
                PacketType          DWORD ?
            ENDS
        ENDS
        OriginalFileObject  PFILE_OBJECT ?
    ENDS
    Apc             KAPC <>
    CompletionKey   PVOID ?
ENDS
IRP_ ENDS

PDEVICE_OBJECT typedef ptr DEVICE_OBJECT

IO_STACK_LOCATION STRUCT 4
MajorFunction       BYTE ?
MinorFunction       BYTE ?
Flags               BYTE ?
Control             BYTE ?

union Parameters

    struct Create
        SecurityContext     PVOID ?
        Options             DWORD ?
        FileAttributes      WORD ?
        ShareAccess         WORD ?
        EaLength            DWORD ?
    ends

    struct Read
        Length_             DWORD ?
        Key                 DWORD ?
        ByteOffset          LARGE_INTEGER <>
    ends

    struct Write
        Length_             DWORD ?
        Key                 DWORD ?
        ByteOffset          LARGE_INTEGER <>
    ends

    struct QueryFile
        Length_                 DWORD ?
        FileInformationClass    DWORD ?
    ends

    struct SetFile
        Length_                 DWORD ?
        FileInformationClass    DWORD ?
        FileObject              PVOID ?
        union
            struct
                ReplaceIfExists BOOLEAN ?
                AdvanceOnly     BOOLEAN ?
            ends
                ClusterCount    DWORD ?
                DeleteHandle    DWORD ?
        ends
    ends

    struct QueryVolume
        Length_                 DWORD ?
        FsInformationClass      DWORD ?
    ends

    struct DeviceIoControl
        OutputBufferLength      DWORD ?
        InputBufferLength       DWORD ?
        IoControlCode           DWORD ?
        Type3InputBuffer        PVOID ?
    ends

    struct QuerySecurity
        SecurityInformation     DWORD ?
        Length_                 DWORD ?
    ends

    struct SetSecurity
        SecurityInformation     DWORD ?
        SecurityDescriptor      PVOID ?
    ends


    struct MountVolume
        Vpb                     PVOID ?
        DeviceObject            PVOID ?
    ends

    struct VerifyVolume
        Vpb                     PVOID ?
        DeviceObject            PVOID ?
    ends

    struct Scsi
        Srb                     PVOID ?
    ends

    struct QueryDeviceRelations
        Type_                   DWORD ?
    ends

    struct QueryInterface
        InterfaceType           DWORD ?
        Size_                   WORD ?
        Version                 WORD ?
        Interface               PVOID ?
        InterfaceSpecificData   PVOID ?
    ends

    struct DeviceCapabilities
        Capabilities            PVOID ?
    ends

    struct FilterResourceRequirements
        IoResourceRequirementList   PVOID ?
    ends

    struct ReadWriteConfig
        WhichSpace              DWORD ?
        Buffer                  PVOID ?
        Offset_                 DWORD ?
        Length_                 DWORD ?
    ends

    struct SetLock
        _Lock                   BOOLEAN ?
    ends

    struct QueryId
        IdType                  DWORD ?
    ends

    struct QueryDeviceText
        DeviceTextType          DWORD ?
        LocaleId                DWORD ?
    ends

    struct UsageNotification
        InPath                  BOOLEAN ?
        ;Reserved                BOOLEAN 3 dup(?)
        Type_                   DWORD ?
    ends 

    struct WaitWake
        PowerState              DWORD ?
    ends

    struct PowerSequence
        PowerSequence           PVOID ?
    ends

    struct WMI
        ProviderId  DWORD ?
        DataPath    PVOID ?
        BufferSize  DWORD ?
        Buffer      PVOID ?
    ends

    struct Others
        Argument1   PVOID ?
        Argument2   PVOID ?
        Argument3   PVOID ?
        Argument4   PVOID ?
    ends

ends

DeviceObject        PDEVICE_OBJECT ?
FileObject          PFILE_OBJECT ?
CompletionRoutine   PVOID ?
Context             PVOID ?

IO_STACK_LOCATION ENDS
