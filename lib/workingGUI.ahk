#Requires Autohotkey v2
;AutoGUI 2.5.8 creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;Easy_AutoGUI_for_AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

myGui := Gui()
DropDownList1 := myGui.Add("DropDownList", "x16 y8 w373", ["Cont1", "", "Cont2", "Cont3"])
ogcButtonViewInput := myGui.Add("Button", "x568 y0 w113 h29", "View Input")
myGui.Add("GroupBox", "x400 y38 w289 h263", "Controller Buttons")
myGui.Add("GroupBox", "x16 y32 w371 h403", "Controller Axes")
myGui.Add("GroupBox", "x400 y304 w286 h130", "Controller Hat")
SB := myGui.Add("StatusBar", , "Status Bar")
DropDownList1.OnEvent("Change", OnEventHandler)
ogcButtonViewInput.OnEvent("Click", OnEventHandler)
myGui.OnEvent('Close', (*) => ExitApp())
myGui.Title := "Empyrion HOSAS Mapper (Clone) (Clone)"
myGui.Show("w701 h468")

OnEventHandler(*)
{
	ToolTip("Click! This is a sample action.`n"
	. "Active GUI element values include:`n"  
	. "DropDownList1 => " DropDownList1.Text "`n" 
	. "ogcButtonViewInput => " ogcButtonViewInput.Text "`n", 77, 277)
	SetTimer () => ToolTip(), -3000 ; tooltip timer
}
