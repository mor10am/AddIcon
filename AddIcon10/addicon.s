;-----------------------------------------------------------------------------
; AddIcon V1.0
; Assembled with PhxAss 4.25
;--------------------------------------------------------------------
; Address:
; 	Morten Amundsen, Hjuksebø, 3670 NOTODDEN, NORWAY
; Telephone:
; 	35 95 74 57
;
;--------------------------------------------------------------------
;
; start: Onsdag, 13. Desember 1995, kl. 14:13
;   end: Onsdag, 13. Desember 1995, kl. 18:35
;
;--------------------------------------------------------------------

VERSION	= 36						; kick version
WB	= 1						; wb startup (0=no)

;--------------------------------------------------------------------

NAME:	MACRO
	dc.b	"addicon"
	ENDM

VER:	MACRO
	dc.b	"1"
	ENDM

REV:	MACRO
	dc.b	"0"
	ENDM

DATE:	MACRO
	dc.b	"(13.12.95)"
	ENDM

VERSTR:	MACRO
	dc.b	"$VER: "
	NAME
	dc.b	" "
	VER
	dc.b	"."
	REV
	dc.b	" "
	DATE
	dc.b	10,13,0
	ENDM

;--------------------------------------------------------------------

	incdir	"include:"
	include	"misc/lvooffsets.i"
	include	"misc/macros.i"
	include	"dos/dosextens.i"
	include	"dos/doshunks.i"
	include	"workbench/workbench.i"

	XDEF	_main
	XDEF	_DOSBase
	XDEF	_IconBase

_main:	movem.l	d0-d7/a0-a6,-(a7)

	sub.l	a1,a1
	EXEC	FindTask
	move.l	d0,a4

	moveq	#0,d0

	tst.l	pr_CLI(a4)
	bne.s	.CLI

	lea	pr_MsgPort(a4),a0
	EXEC	WaitPort
	lea	pr_MsgPort(a4),a0
	EXEC	GetMsg
.CLI:	move.l	d0,_WBMsg
	bne.s	EXIT					; shell only

;--------------------------------------------------------------------

	OPENLIB	DOSName,VERSION,_DOSBase
	beq.s	EXIT
	OPENLIB	IconName,VERSION,_IconBase
	beq.s	EXIT

;--------------------------------------------------------------------

	moveq	#DOS_FIB,d1
	moveq	#0,d2
	CALL	AllocDosObject,_DOSBase
	move.l	d0,_FIB
	bne.s	OK_FIB

	CALL	IoErr,_DOSBase
	move.l	d0,d1
	moveq	#0,d2
	CALL	PrintFault,_DOSBase
	bra.s	EXIT

OK_FIB:	move.l	#Template,d1
	move.l	#ArgArray,d2
	moveq	#0,d3
	CALL	ReadArgs,_DOSBase		; process commandline
	move.l	d0,_RDArgs			; arguments
	bne.s	OK_ARG

	CALL	IoErr,_DOSBase
	move.l	d0,d1
	moveq	#0,d2
	CALL	PrintFault,_DOSBase		; print argument fault
	bra.s	EXIT

OK_ARG:	lea	ArgArray,a0
	tst.l	arg_DefTool(a0)
	beq.s	NO_DEF

	move.l	arg_DefTool(a0),DefTool

NO_DEF:	lea	ArgArray,a0
	move.l	arg_Icon(a0),a0
	CALL	GetDiskObject,_IconBase
	move.l	d0,_ForceIcon			; icon to add to files
	bne.s	OK_ICN

	CALL	IoErr,_DOSBase
	move.l	d0,d6
	cmp.l	#ERROR_OBJECT_NOT_FOUND,d0
	bne.s	.NOT

	move.l	#RParTxt,d1
	CALL	PutStr,_DOSBase

	lea	ArgArray,a0
	move.l	arg_Icon(a0),d1
	CALL	PutStr,_DOSBase

	move.l	#InfoTxt,d1
	CALL	PutStr,_DOSBase

	move.l	#LParTxt,d1
	CALL	PutStr,_DOSBase

.NOT:	move.l	d6,d1
	moveq	#0,d2
	CALL	PrintFault,_DOSBase
	bra.s	EXIT

OK_ICN:	move.l	d0,a0
	move.l	do_ToolTypes(a0),_OldToolTypes
	move.l	do_DefaultTool(a0),_OldDefaultTool
	move.b	do_Type(a0),_OldType
	move.l	do_DrawerData(a0),_OldDrawerData
	move.l	do_ToolWindow(a0),_OldToolsWindow
	move.l	do_StackSize(a0),_OldStackSize

	lea	ArgArray,a0
	move.l	arg_Files(a0),a4
MAIN_LOOP:
	move.l	(a4)+,a5
	cmp.l	#NULL,a5
	beq.s	EXIT

	move.l	a5,d1
	move.l	#MODE_OLDFILE,d2
	CALL	Open,_DOSBase
	move.l	d0,d6
	bne.s	CHECK_TYPE

	CALL	IoErr,_DOSBase
	move.l	d0,d6

	move.l	#RParTxt,d1
	CALL	PutStr,_DOSBase

	move.l	a5,d1
	CALL	PutStr,_DOSBase

	move.l	#LParTxt,d1
	CALL	PutStr,_DOSBase

	move.l	d6,d1
	moveq	#0,d2
	CALL	PrintFault,_DOSBase
	bra.s	MAIN_LOOP

CHECK_TYPE:
	move.l	d6,d1
	move.l	_FIB,d2
	CALL	ExamineFH,_DOSBase

	move.l	_FIB,a0
	move.l	fib_DirEntryType(a0),d0
	bgt.s	SKIP_DIR

	move.l	d6,d1				; read 1st 4 bytes of file
	move.l	#ReadBuffer,d2
	move.l	#4,d3
	CALL	Read,_DOSBase

	lea	ReadBuffer,a0
	cmp.l	#HUNK_HEADER,(a0)		; excutable?
	bne.s	PROJECT_TYPE			; nope... datafile!

	move.l	_ForceIcon,a1
	move.b	#WBTOOL,do_Type(a1)
	move.l	#0,do_DrawerData(a1)
	move.l	#0,do_ToolTypes(a1)
	move.l	#0,do_DefaultTool(a1)
	move.l	#0,do_ToolWindow(a1)
	move.l	#4096,do_StackSize(a1)
	bra.s	PUT_ICON

PROJECT_TYPE:
	move.l	_ForceIcon,a1
	move.b	#WBPROJECT,do_Type(a1)
	move.l	#0,do_DrawerData(a1)
	move.l	#0,do_ToolTypes(a1)
	move.l	DefTool,do_DefaultTool(a1)	; default=MultiView
	move.l	#0,do_ToolWindow(a1)
	move.l	#0,do_StackSize(a1)

PUT_ICON:
	move.l	d6,d1
	CALL	Close,_DOSBase

	move.l	a5,a0
	move.l	_ForceIcon,a1
	CALL	PutDiskObject,_IconBase
	bra.w	MAIN_LOOP

SKIP_DIR:
	move.l	d6,d1
	CALL	Close,_DOSBase
	bra.s	MAIN_LOOP

;--------------------------------------------------------------------

EXIT:	bsr.w	FREE_FIB
	bsr.w	FREEARGS
	bsr.w	FREE_FORCEICON

	bsr.w	CLOSEDOS
	bsr.w	CLOSEICON

	tst.l	_WBMsg
	beq.s	.NOT

	EXEC	Forbid
	move.l	_WBMsg,a1
	EXEC	ReplyMsg
	EXEC	Permit
.NOT:	movem.l	(a7)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

;--------------------------------------------------------------------

FREE_FIB:
	tst.l	_FIB
	beq.s	.NOT

	moveq	#DOS_FIB,d1
	move.l	_FIB,d2
	CALL	FreeDosObject,_DOSBase
.NOT:	rts

FREEARGS:
	tst.l	_RDArgs
	beq.s	.NOT

	move.l	_RDArgs,d1
	CALL	FreeArgs,_DOSBase
.NOT:	rts

FREE_FORCEICON:
	tst.l	_ForceIcon
	beq.s	.NOT

	move.l	_ForceIcon,a0
	move.l	_OldToolTypes,do_ToolTypes(a0)
	move.l	_OldDefaultTool,do_DefaultTool(a0)
	move.b	_OldType,do_Type(a0)
	move.l	_OldDrawerData,do_DrawerData(a0)
	move.l	_OldToolsWindow,do_ToolWindow(a0)
	move.l	_OldStackSize,do_StackSize(a0)

	CALL	FreeDiskObject,_IconBase
.NOT:	rts

;--------------------------------------------------------------------

CLOSEDOS:
	tst.l	_DOSBase
	beq.s	.NOT

	CLOSELIB _DOSBase
.NOT:	rts

CLOSEICON:
	tst.l	_IconBase
	beq.s	.NOT

	CLOSELIB _IconBase
.NOT:	rts

;-----------------------------------------------------------------------------

	section	"Data",data

_WBMsg:		dc.l	0

_DOSBase:	dc.l	0
_IconBase:	dc.l	0
DOSName:	dc.b	"dos.library",0
IconName:	dc.b	"icon.library",0
		VERSTR
		even

;----------------------------------------------------------------------------

_FIB:		dc.l	0
_RDArgs:	dc.l	0

; ArgArray offsets

arg_Files:	equ	0	; filelist
arg_Icon:	equ	4	; icon name to add to files in list
arg_DefTool:	equ	8	; default tool

ArgArray:	dcb.l	3,0

Template:	dc.b	"FILES/A/M,ICON/A/K,TOOL/K",0
RParTxt:	dc.b	"(",0
LParTxt:	dc.b	") ",0
InfoTxt:	dc.b	".info",0
		even

;--------------------------------------------------------------------

DefTool:		dc.l	DefToolTxt
DefToolTxt:		dc.b	"MultiView",0
			even
ReadBuffer:		dc.l	0
_ForceIcon:		dc.l	0		; icon to add

_OldToolTypes:		dc.l	0
_OldDefaultTool:	dc.l	0
_OldDrawerData:		dc.l	0
_OldToolsWindow:	dc.l	0
_OldStackSize:		dc.l	0
_OldType:		dc.b	0
			even

NewDrawerData:		dcb.b	DrawerData_SIZEOF,0

;--------------------------------------------------------------------
