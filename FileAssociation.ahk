#NoEnv
#NoTrayIcon
#SingleInstance, force
SetWorkingDir %A_ScriptDir%

app:="SumatraPDF.exe" ; имя приложения в папке скрипта

ext_string:="pdf|djv,djvu|fb2,fb2z|epub|xps,oxps|mobi|ps|pdb|cb7,cb7z|cbr|cbz|cbt"

exclude:=""

If !A_IsAdmin && !(A_OSVersion~="WIN_2003|WIN_XP"){
	MsgBox, 48, , Требуется запуск от имени администратора!, 1.5
	ExitApp
}

If !FileExist(app) {
	MsgBox, 48, , Отсутствует файл %app% в папке программы!, 1.5
	ExitApp
}
app_name:=RegExReplace(app,"\.exe$")
app_path:=A_ScriptDir "\" app
Loop Parse, ext_string, |
	r:=A_Index
nraw:=(r>16)?16:r
Gui -DPIScale +ToolWindow
Gui Default
Gui Color, 72A0C1
Gui Font, s11
Gui Add, ListView, x12 y12 R%nraw% w280 -Multi Grid Checked NoSort, Выберите расширения:
ImageListID := IL_Create()
LV_SetImageList(ImageListID)
Loop Parse, ext_string, |
{
	icn:=A_Index, icn_found:=0
	Loop Parse, A_LoopField, CSV
	{
		If FileExist("icons\" A_LoopField ".ico") {
			IL_Add(ImageListID, "icons\" A_LoopField ".ico")
			icn_found:=1
			break
		}
	}
	If !icn_found
		IL_Add(ImageListID,app,1)
	LV_Add("Check Icon" A_Index,A_LoopField)
	raw++
}
If (r>nraw)
	LV_ModifyCol(1,240)
Gui Font, s9
Gui Add, Button, x16 y+8 w134 h30 gSelectAll, Выбрать все
Gui Add, Button, x156 yp w134 h30 gSelectNo, Ни одного
Gui Add, Button, x156 y+8 w134 h30 gAssociate, &OK
Gui Add, Button, x16 yp w134 h30 gGuiClose, Cancel
Gui Show, , Ассоциация файлов
Return

GuiEscape:
GuiClose:
	ExitApp

SelectAll:
	Loop % raw
		LV_Modify(A_Index, "+Check")
	return
	
SelectNo:
	Loop % raw
		LV_Modify(A_Index, "-Check")
	return


Associate:
	Gui Submit
	raw:=0
	Loop {
		raw:=LV_GetNext(raw,"C")
		If !raw
			break
		LV_GetText(exts,raw)
		icon:=""
		Loop Parse, % exts, CSV
		{
			If FileExist("icons\" A_LoopField ".ico") {
				icon:=A_ScriptDir "\icons\" A_LoopField ".ico"
				break
			}
		}
		Loop Parse, % exts, CSV
		{
			StringUpper ext, A_LoopField
			If (A_LoopField~=exclude)
				RegDelete HKCR, % "." A_LoopField, AHK_DEFAULT
			else
				RegDelete HKCR, % "." A_LoopField
				
			RegDelete HKCR, % app_name "." ext		
			RegWrite, REG_SZ, HKCR, % "." A_LoopField, , % app_name "." ext
			RegWrite, REG_SZ, HKCR, % app_name "." ext, , % app_name " " ext " File"	
			RegWrite, REG_SZ, HKCR, % app_name "." ext "\Shell\Open\Command", , "%app_path%" "`%1"
			icon:=icon ? icon : app_path ",1"		
			RegWrite, REG_SZ, HKCR, % app_name "." ext "\DefaultIcon", , % icon
			count++
		}
	}
	If count
		MsgBox, 64, , Выполнено!, 1.5
	return



	