#NoEnv
#SingleInstance, force
SetTitleMatchMode, 2
SetTitleMatchMode, Slow
SetKeyDelay 50, 50
FileEncoding UTF-8


font:=13 ; размер шрифта панели страниц
file_show:=3000 ; время показа имени файла в панели страниц
color:="4E8D8F" ; ее цвет

;-----------------------------------------
EnvSet __COMPAT_LAYER, RUNASINVOKER

fn:=[], wd:=A_WorkingDir
Loop % A_Args.Length()	
{
	p:=A_Args[A_Index]
	If (p~=".+\.\w{2,5}$")
		fn.Push(" """ p """")
	else
		par.=" " p
}
SysGet, M, MonitorWorkArea
SetWorkingDir %A_ScriptDir%
FileCreateDir Data
FileCreateDir Shortcuts
SplitPath A_ScriptDir, , , , , script_drive
working_file:="SumatraPDFx32.exe"
If A_Is64bitOS && FileExist("Bin\SumatraPDFx64.exe")
	working_file:="SumatraPDFx64.exe"
If !FileExist("Data\*.txt")
	FileCopy Defaults\*.txt, Data
If FileExist("Data\SumatraPDF-settings_*.txt") {
	Loop Files, Data\SumatraPDF-settings_*.txt
	{
		all_profiles:=A_Index
		If (A_Index=1)
			profile1:=A_LoopFileName
		Hotkey IFWinActive, ahk_class SUMATRA_PDF_FRAME
		Hotkey % "!" A_Index, Profile
	}
	Loop Files, Bin\SumatraPDF-settings_*.txt
		last:=A_LoopFileName
	FileDelete Bin\SumatraPDF-settings_*.txt
	If (!last || !FileExist("Data\" last))
		last:=profile1
	FileCopy % "Data\" last, Bin\SumatraPDF-settings.txt, 1
	RegExMatch(last,"\d", profile)
}
else {
	FileCopy Data\SumatraPDF-settings_1.txt, Bin
	last:=profile1
	If (FileExist("ReadMe.pdf") && !fn[1])
		par:=" ReadMe.pdf"
}
If !fn.Length()
	fn.Push("")
Loop % Fn.Length()
{
	Run % "Bin\" working_file . par . fn[A_Index], % wd
	Sleep 50
}

Menu Tray, NoStandard
Loop Files, Data\*.txt
	Menu Profiles, Add, % A_LoopFileName, SelectProfile
Menu Profiles, Add
Menu Profiles, Add, Новый профиль, !vk4E
Menu Tray, Add, Профили, :Profiles
Menu Tray, Add, Папка настроек, DataFolder
Menu Tray, Add
Menu Tray, Add, Создать заметку, !vk53
Menu Tray, Add, Заметки к текущему файлу, FileNotes
Menu Tray, Add, Папка заметок, NotesFolder
Menu Tray, Add
Menu Edit, Add, Приложение по умолчанию, RunDefault
Loop Files, Shortcuts\*.*
{
	If (A_LoopFileName~="\.(lnk|bat)$")
		Menu Edit, Add, % A_LoopFileName, Edit
}
Menu Edit, Add
Menu Edit, Add, Папка ярлыков, Shortcuts
Menu Tray, Add, Открыть с помощью, :Edit
Menu Tray, Add, Дублировать вкладку, +Tab
Menu Tray, Add
Menu Tray, Add, % "Сохранить в папку " script_drive "\ _Read", ^+vk53
Menu Tray, Add, Сохранить на рабочий стол, ^+vk44
Menu Tray, Add, Ярлык на рабочем столе, ^+vk5A
Menu Tray, Add
Menu Tray, Add, Копировать файл, ^+vk43
Menu Tray, Add, Копировать путь к файлу, ^+vk50
Menu Tray, Add
Menu Tray, Add, Выход, Exit
goto Start

SelectProfile:
RegExMatch(A_ThisMenuItem,"\d",pr)
goto SetProfile

DataFolder:
Run Data
return

FileNotes:
If FileExist("Notes\" sfn ".txt")
	Run % "Notes\" sfn ".txt"
Else
	MsgBox 0x40, , Отсутствуют заметки к открытому файлу!, 1.5
return

NotesFolder:
Run Notes
return

Exit:
WinClose ahk_class SUMATRA_PDF_FRAME
If profile { ;#[SumatraPDF]
	FileMove Bin\SumatraPDF-settings.txt, % "Bin\SumatraPDF-settings_" profile ".txt", 1 ;#[SumatraPDF]
	FileCopy  % "Bin\SumatraPDF-settings_" profile ".txt", % "Data\SumatraPDF-settings_" profile ".txt", 1
}
ExitApp


Start:
WinWait ahk_class SUMATRA_PDF_FRAME
WinActivate
If FileExist(A_ScriptDir "\max.txt") 
	WinMaximize

Loop
{
	WinGetTitle st, ahk_class SUMATRA_PDF_FRAME
	RegExMatch(st,"^[a-zA-Z]:\\.+?\.\w{2,4}(?= - )",sf)
	If WinActive("ahk_exe " working_file) && sf
	{
		If (sf!=sf_old)
		{
			show:=1, sf_old:=sf
			SetTimer Show, % file_show
			Sleep 50
			Send {vk52}
		}
		SplitPath sf, sfn, sd, sfext
		WinGetText stxt, ahk_class SUMATRA_PDF_FRAME
		RegExMatch(stxt,"m)^[0-9XIVLCxivlc]+$",pg)
		RegExMatch(stxt,"m)/ ?\K[0-9]+",all_pg)
		If (pg~="[a-zA-Z]+")
			pg:=Roman_Decode(pg)
		pp:=pg " / " all_pg
		If show && file_show
		{
			FileGetSize sz, % sf, K
			pp.=" | " sfn "  (" sz " KB)"
		}
		If (WinState("ahk_class SUMATRA_PDF_FRAME")=2 && !show)
		{
			FormatTime time, , HH:mm
			pp.=" | " time
		}
		ControlGetText pp_old, Static1, pages_window
		l:=StrLen(pp), l_old:=StrLen(pp_old)
		WinGetPos x, y, w, h, ahk_class SUMATRA_PDF_FRAME
		If (!WinExist("pages_window") || (l!=l_old) || reload)
		{
			Gui Destroy
			Gui -Caption +ToolWindow -DPIScale +AlwaysOnTop +LastFound
			Gui Color, % color
			Gui Font, s%font% cffffff w700
			Gui Margin, 6, 2
			Gui Add, Text,, % pp
			If all_profiles
			{
				Gui Font, s9
				Gui Add, Text, ys, % profile
			}
			Gui Show, x10 y10 NA, pages_window
			WinGetPos, , , , hp
			OnMessage(0x201, "WM_LBUTTONDOWN")
			OnMessage(0x204, "WM_RBUTTONDOWN")
			OnMessage(0x207, "WM_MBUTTONDOWN")
			If reload
				reload:=0
		}
		GuiControl Text, Static1, % pp
		GuiControl Text, Static2, % profile
		WinMove, pages_window, ,x+12, y+h-hp-12
	}
	else
		Gui Destroy
	Process Exist, % working_file
	If !Errorlevel
		count+=1
	If (count>10)
		goto Exit
	Sleep 50
}

Show:
SetTimer Show, Off
show:=0
return

WM_LBUTTONDOWN() {
	global
	WinSet Top,, pages_window
	show:=1
	SetTimer Show, % file_show
}

WM_RBUTTONDOWN() {
	KeyWait LButton, T1
	WinActivate ahk_class SUMATRA_PDF_FRAME
	Send !{Left}
}

WM_MBUTTONDOWN() {
	KeyWait MButton, T1
	WinActivate ahk_class SUMATRA_PDF_FRAME
	Send ^{vk47}
}

WM_MOUSEMOVE() {
	ToolTip % all_profiles ? "Профиль " profile,,, 3
	Sleep 1500
	ToolTip,,,, 3
}

#If WinActive("ahk_class SUMATRA_PDF_FRAME")
!Down:: ; Избранное
KeyWait RButton, T1
KeyWait LAlt, T1
SendInput {Alt}{Down 6}{Right}{Down 2}{Enter}
return

^NumpadEnter::
^Enter::Send {F11}

F1:: ; Вызов справки
If FileExist("ReadMe.pdf")
	Run % "Bin\" working_file " ReadMe.pdf"
return

+RButton::
KeyWait RButton, T1
KeyWait Shift, T1
Menu Edit, Show
return

Shortcuts:
Run explorer.exe /root`, %A_ScriptDir%\Shortcuts
return

!vk4E:: ; Alt+N - создание нового профиля
KeyWait Alt, T1
FileCreateDir Data
Loop Files, Data\SumatraPDF-settings_*.txt
	all_profiles:=A_Index
If !all_profiles
	all_profiles:=0
If (all_profiles>=9)
{
	MsgBox, 16, , Невозможно создание более 9 профилей!, 1.
	return
}
profile:=all_profiles+=1
;~ profile:=(all_profiles ? all_profiles+1 : 1)
FileCopy Bin\SumatraPDF-settings.txt, % "Data\SumatraPDF-settings_" profile ".txt", 1
MsgBox, 64, , % "Создан профиль номер " profile "`nГорячая клавиша Alt+" profile, 2
Hotkey IFWinActive, ahk_class SUMATRA_PDF_FRAME
Hotkey % "!" profile, Profile
reload:=1
Sleep 100
WinActivate ahk_class SUMATRA_PDF_FRAME
return

Profile:
KeyWait Alt, T1
RegExMatch(A_ThisHotkey,"\d", pr)
SetProfile:
If pr && (pr!=profile) && FileExist("Data\SumatraPDF-settings_" pr ".txt")
{
	FileRead set_old, Bin\SumatraPDF-settings.txt
	FileMove Bin\SumatraPDF-settings.txt, % "Data\SumatraPDF-settings_" profile ".txt", 1
	profile:=pr
	FileRead set_new, % "Data\SumatraPDF-settings_" profile ".txt"
	FileAppend % RegExReplace(set_new,"s)FileStates.*$") . RegExReplace(set_old, "s)^.+(?=FileStates)"), Bin\SumatraPDF-settings.txt		
	Sleep 50
}
Sleep 100
WinActivate ahk_class SUMATRA_PDF_FRAME
Send {vk52}
reload:=1
return

#If WinActive("ahk_class SUMATRA_PDF_FRAME") && sf
	!Up::Send {F12}


^Space::WM_LBUTTONDOWN() ; имя файла

RunDefault:
Run % """" sf """"
Return

Edit:		
Run % "Shortcuts\" A_ThisMenuItem (sf ? " """ sf """" : "")
return

^+vk43:: ; Ctrl+Shift+C копирование файла
WinActivate ahk_class SUMATRA_PDF_FRAME
Sleep 50
If sf {
	Clipboard:=""
	FileToClipboard(sf)
	If Clipboard
		MsgBox 0x40, , Файл в буфере!, 1
}
return

^+vk50:: ; Ctrl+Shift+P копирование полного пути к файлу
Clipboard:=sf
ToolTip Путь к файлу в буфере!, MRight//2-100, MBottom//2
Sleep 1000
ToolTip
return

+Tab:: ; Shift+Tab - открытие дубликата книги
WinActivate ahk_class SUMATRA_PDF_FRAME
Sleep 50
Send ^{vk4F}
WinWaitActive % "ahk_class #32770 ahk_exe " working_file
ControlSetText Edit1, % sf
ControlSend Button1, {Enter}
return

^+vk53::SaveCopy(script_drive "\_Read") ; Ctrl+Shift+S - сохранение в папку _Read
^+vk44::SaveCopy(A_Desktop) ; Ctrl+Shift+D - сохранение на рабочий стол

SaveCopy(path) {
	global
	WinActivate ahk_class SUMATRA_PDF_FRAME
	Sleep 50
	KeyWait Ctrl, T1
	KeyWait Shift, T1
	If !sfn
		Return
	FileCreateDir % path
	Send ^{vk53}
	WinWaitActive % "ahk_class #32770 ahk_exe " working_file
	SendInput % "{raw}" path
	Send {Enter}
	Sleep 100
	SendInput % "{raw}" sfn
	Sleep 100
	Send {Enter}
	return
}

^+vk5A:: ; Ctrl+Shift+Z - ярлык на рабочем столе
WinActivate ahk_class SUMATRA_PDF_FRAME
Sleep 50
SplitPath % sf,,,, fn
FileCreateShortcut % sf, % A_Desktop "\" fn ".lnk"
If FileExist(A_Desktop "\" fn ".lnk")
	MsgBox, 64, , Ярлык %fn% создан!, 1.5
return


^+vk4F:: ; Ctrl+Shift+O - увеличенное окно открытия файла с подсветкой текущего
KeyWait Ctrl, T1
KeyWait vk4F, T1
Send ^{vk4F}
WinWaitActive % "ahk_class #32770 ahk_exe " working_file
Sleep 100
WinMove ahk_class #32770, , MRight//6, MBottom//20, MRight*0.68, MBottom*0.9
ControlSetText Edit1, % sd #32770
ControlSend Button1, {Enter}
Sleep 100
ControlFocus DirectUIHWND2, ahk_class #32770
SendInput ^+6
Sleep 100
SendInput % sfn
return

+F2:: ; Shift+F2 - переименование файлов
KeyWait Shift, T1
Clipboard:=""
Send ^{vk43}
ClipWait 1
e:=Errorlevel
ren:=ValidName(Trim(Clipboard))
Clipboard:=FirstUppercase(RegExReplace(ren,"[.,]+$"))
Send {F2}
WinWaitActive ahk_class #32770
If e
{
	ToolTip Ничего не скопировано!, MRight//2-100, MBottom//2
	Sleep 1500
	ToolTip
	return
}
Send {Del}
Sleep 200
Send ^{vk56}
ControlSend Edit1, {End}
return

^Del:: ; Ctrl+Del - удаление файла
^NumpadDel::
KeyWait Ctrl, T1
If !sf_old
	return
SplitPath sf_old, sf_name
MsgBox, 33, , % "Удалить файл`n" sf_name "`nв корзину ?"
IfMsgBox Cancel
	return


!Home::
!End::
!PGUP::
!PGDN::
^!PGUP::
^!PGDN::
start:=sf_old
SplitPath start, , dir
mask:="*.cb7*;*.cbr;*.cbt;*.cbz;*.chm;*.djv*;*.epub;*.fb2;*.fb2z;*.fb2.zip;*.mobi;*.pdb;*.pdf;*.xps;*.oxps;*.ps"
n:=0, curr:=next:=prev:=end:=""
Loop Parse, mask, `;
{
	Loop Files, % dir "\" A_LoopField
	{
		n+=1
		If (n=1)
			home:=A_LoopFileFullPath
		If (A_LoopFileFullPath=start)
			curr:=n, prev:=end
		If (n=curr+1)
			next:=A_LoopFileFullPath
		end:=A_LoopFileFullPath
	}
}
open:=next, text:="Последний файл папки!"
If A_ThisHotkey in !PGUP,^!PGUP
	open:=prev, text:="Первый файл папки!"
If (A_ThisHotkey="!Home")
	open:=home, text:="Открыто!"
If (A_ThisHotkey="!End")
	open:=end, text:="Открыто!"
If (A_ThisHotkey~="Del")
{
	WinGetActiveTitle cl_tab
	Send ^{vk57}
	WinWaitNotActive % cl_tab, , 2
	Sleep 100
	FileRecycle % start
}
If (!open || open=start)
{
	ToolTip % text, MRight//2-100, MBottom//2
	Sleep 1000
	ToolTip
	return
}
If A_ThisHotkey not contains Del,^!
{
	WinGetActiveTitle cl_tab
	Send ^{vk57}
	WinWaitNotActive % cl_tab, , 2
}
WinGet sumatra, ProcessPath, A
Run "%sumatra%" "%open%"
return


!vk53::
If WinExist("Редактор заметок ahk_class AutoHotkeyGUI") {
	MsgBox 0x40, , Закройте окно редактора заметок!, 1.5
	Return
}
KeyWait LAlt, T1
tmp:=Clipboard, Clipboard:=note:=""
WinActivate ahk_class SUMATRA_PDF_FRAME
Sleep 50
Send ^{vk43}
ClipWait 0.5
Gui 2:Destroy
Gui 2:+hWndhMainWnd +AlwaysOnTop -DPIScale
Gui 2:Color, 72A0C1
Gui 2:Font, s13
Gui 2:Add, Edit, x15 y16 w870 h530 vnote, % Clipboard
Gui 2:Font, s10
Gui 2:Add, Button, x250 y560 w191 h32 g2GuiClose, Cancel
Gui 2:Add, Button, x458 y560 w191 h32 gSaveNote, &OK
Gui 2:Show, w900 h600, Редактор заметок
Send ^{End}
Return

SaveNote:
GUI Submit
If !note
	Return
FileCreateDir Notes
FileAppend % "### " pg "/" all_pg "  " A_DD "." A_MM "." A_YYYY "  " A_Hour ":" A_Min " ###`r`n" note "`r`n`r`n`r`n", % "Notes\" sfn ".txt"
Return

2GuiClose:
Gui 2:Destroy
Return

#If Winactive("Редактор заметок ahk_class AutoHotkeyGUI")
	Esc::goto 2GuiClose

#If WinActive("ahk_class SUMATRA_PDF_FRAME") && IsBorder(1) && WinState()
	LButton::Send {F12}
RButton::goto !Down

MButton::
KeyWait MButton, T1
Clipboard:=""
Send ^{vk43}
ClipWait 0.5
fav:=RegExReplace(Clipboard,"\s"," ")
SendInput {Alt}{Down 6}{Right}{Enter}
WinWaitActive % "ahk_class #32770 ahk_exe " working_file
If fav {
	ControlGetText f0, Edit1
	ControlSetText Edit1, % f0 " [" fav "]", ahk_class #32770
}
return

#If WinActive("ahk_class SUMATRA_PDF_FRAME") && IsBorder(0,1) && WinState()
	MButton up::Send {F11}
RButton::^vk44 ; Свойства файла

#If WinActive("ahk_class SUMATRA_PDF_FRAME") && IsBorder(0,0,1) && WinState()
	MButton up::goto ^+vk4F ; Ctrl+Shif+O

RButton::
KeyWait Ctrl, T1
KeyWait Shift, T1
SendInput {Alt}{Down 2}{Right}{Down 9}{Enter}
return

#If WinActive("ahk_class SUMATRA_PDF_FRAME") && !IsBorder(1,1,1,1)
	~RButton & WheelDown::SendInput ^{Tab}
~RButton & WheelUp::SendInput ^+{Tab}

~RButton & LButton::
SendInput !{Left}
KeyWait RButton, T1
Sleep 100
Send {Esc}
return

~LButton & RButton::SendInput !{Right}

#If WinActive("ahk_class #32770 ahk_exe " working_file)
MButton::!Up
#If

;--------------------------------------------------
FirstUppercase(t)
{
	StringLeft n, t, 1
	StringTrimLeft k, t, 1
	StringUpper n, n
	return n . k
}

IsBorder(left:="",right="",top="",bottom:="",m=6)
{
	SysGet, M, Monitor
	SysGet, W, MonitorWorkArea
	CoordMode Mouse
	MouseGetPos mx, my
	return If (((left && mx<m) && (my>50) && (my<WBottom)) || (right && mx>MRight-m) || (top && my<m) || (bottom && my>MBottom-m))
}

ValidName(n,r="")
{
	n:=RegExReplace(n,"(:|;|,|\.|\*|\?|\\|/|<|>|"")"," ")
	n:=RegExReplace(n,"\s+"," ")
	StringReplace n, n, |, -, All
	If r
		StringReplace n, n, % " ", % r, All
	return Trim(n)
}

WinState(t="A")
{
	If !WinExist(t) || (t="A" && WinActive("Program Manager"))
		return
	SysGet, M, Monitor
	WinGetPos , , , w, h, % t
	WinGet st, MinMax, % t
	If (w=MRight && h=MBottom)
		st:=2
	return st
}

FileToClipboard(PathToCopy,Method="copy")
{
	FileCount:=0
	PathLength:=0
	
   ; Count files and total string length
	Loop,Parse,PathToCopy,`n,`r
	{
		FileCount++
		PathLength+=StrLen(A_LoopField)
	}
	
	pid:=DllCall("GetCurrentProcessId","uint")
	hwnd:=WinExist("ahk_pid " . pid)
   ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40)
	hPath := DllCall("GlobalAlloc","uint",0x42,"uint",20 + (PathLength + FileCount + 1) * 2,"UPtr")
	pPath := DllCall("GlobalLock","UPtr",hPath)
	NumPut(20,pPath+0),pPath += 16 ; DROPFILES.pFiles = offset of file list
	NumPut(1,pPath+0),pPath += 4 ; fWide = 0 -->ANSI,fWide = 1 -->Unicode
	Offset:=0
	Loop,Parse,PathToCopy,`n,`r ; Rows are delimited by linefeeds (`r`n).
		offset += StrPut(A_LoopField,pPath+offset,StrLen(A_LoopField)+1,"UTF-16") * 2
	
	DllCall("GlobalUnlock","UPtr",hPath)
	DllCall("OpenClipboard","UPtr",hwnd)
	DllCall("EmptyClipboard")
	DllCall("SetClipboardData","uint",0xF,"UPtr",hPath) ; 0xF = CF_HDROP
	
   ; Write Preferred DropEffect structure to clipboard to switch between copy/cut operations
   ; 0x42 = GMEM_MOVEABLE(0x2) | GMEM_ZEROINIT(0x40)
	mem := DllCall("GlobalAlloc","uint",0x42,"uint",4,"UPtr")
	str := DllCall("GlobalLock","UPtr",mem)
	
	if (Method="copy")
		DllCall("RtlFillMemory","UPtr",str,"uint",1,"UChar",0x05)
	else if (Method="cut")
		DllCall("RtlFillMemory","UPtr",str,"uint",1,"UChar",0x02)
	else
	{
		DllCall("CloseClipboard")
		return
	}
	
	DllCall("GlobalUnlock","UPtr",mem)
	
	cfFormat := DllCall("RegisterClipboardFormat","Str","Preferred DropEffect")
	DllCall("SetClipboardData","uint",cfFormat,"UPtr",mem)
	DllCall("CloseClipboard")
	return
}

Roman_Decode(str){
	res := 0
	Loop Parse, str
	{
		n := {M: 1000, D:500, C:100, L:50, X:10, V:5, I:1}[A_LoopField]
		If ( n > OldN ) && OldN
			res -= 2*OldN
		res += n, oldN := n
	}
	return res
}
