#Requires AutoHotkey v2.0
#SingleInstance Force

#include "lib\PhysicalController.ahk"
#include "lib\EGS_InputConfig.ahk"
#include "lib\Support.ahk"

EGS_InputConfig_filepath := "D:\steam\steamapps\common\Empyrion - Galactic Survival\Saves\inputconfig_v35.xml"
EGS_ControlProfiles_path := "settings\Profiles\"


class EGSHosasWrapper {
	Controllers := Map()
	HardwareIDs := Array()
	ControllerNames := Array()
	JoyIDs := Array()
	
	selectedController := ""
	
	__New() {
		;Query for each possible (1 to 16) controller id and 
		;create controller objects for all that are found/active.
		loop (16) {
			if (GetKeyState(A_Index . "JoyName") != "") {
				newCont := PhysicalController(A_Index)
				
				this.Controllers[newCont.HardwareID] := newCont
				this.HardwareIDs.push(newCont.HardwareID)
				this.ControllerNames.push(newCont.Name)
				this.JoyIDs.push(newCont.JoyID)
			}
		}
	}
	
	Start(inputCfg) {		
		this.window := Gui(,"Empyrion HOSAS Mapper")
		this.window.OnEvent('Close', (*) => ExitApp())
		
		this.window.MenuBar := MenuBar()
		
		FileMenu := Menu()
		FileMenu.Add("&New", this.CB_MenuHandler.Bind(this))
		FileMenu.Add("&Save", this.CB_MenuHandler.Bind(this))
		FileMenu.Add("&Load", this.CB_MenuHandler.Bind(this))
		FileMenu.Add()
		FileMenu.Add("E&xit", (*) => ExitApp())
		
		this.window.MenuBar.Add("&File", FileMenu)
		
		this.window.AddDropDownList("vddlController x8 y8 w320", this.ControllerNames)
		this.window["ddlController"].OnEvent("Change", this.CB_ControlListHandler.Bind(this))
		
		this.window.AddGroupBox(format("x{1} y{2} w{3} h{4}", 336, 8, 320, 80), "Input")
		this.window.AddText("vedtControllerState x344 y24 w300 r4", "No Controller Selected")
		
		this.window["ddlController"].Value := 1
		this.CB_ControlListHandler(this.window["ddlController"])
		
		;Build Axes Section
		axisBox := Rect(8, 32, 320, 240)
		
		this.window.AddGroupBox(format("x{1} y{2} w{3} h{4}", axisBox.x, axisBox.y, axisBox.w, axisBox.h), "Axes")
		this.CreateAxisControls("X", 24,  56, [], this.CB_EventHandler.Bind(this))
		this.CreateAxisControls("Y", 24,  88, [], this.CB_EventHandler.Bind(this))
		this.CreateAxisControls("Z", 24, 120, [], this.CB_EventHandler.Bind(this))
		
		this.CreateAxisControls("R", 24, 168, [], this.CB_EventHandler.Bind(this))
		this.CreateAxisControls("U", 24, 200, [], this.CB_EventHandler.Bind(this))
		this.CreateAxisControls("V", 24, 232, [], this.CB_EventHandler.Bind(this))
		
		;Build Hat Section
		hatBox := Rect(336, 96, 320, 132)
		this.window.AddGroupBox(format("x{1} y{2} w{3} h{4}", hatBox.x, hatBox.y, hatBox.w, hatBox.h), "Hat")
		this.CreateHatControls("Up",    hatBox.x + 16, 112, [], this.CB_EventHandler.Bind(this))
		this.CreateHatControls("Down",  hatBox.x + 16, 140, [], this.CB_EventHandler.Bind(this))
		this.CreateHatControls("Left",  hatBox.x + 16, 168, [], this.CB_EventHandler.Bind(this))
		this.CreateHatControls("Right", hatBox.x + 16, 196, [], this.CB_EventHandler.Bind(this))
		
		btnBox := Rect(8, 272, 320, 316)
		tabTitles := ["Buttons 1-8", "Buttons 9-16", "Buttons 17-24", "Buttons 25-32"]
		this.ButtonTabs := this.window.AddTab3(format("x{1} y{2} w{3} h{4}", btnBox.x, btnBox.y, btnBox.w, btnBox.h), tabTitles)
		
		;Build Button Section
		this.AllTabDDLs := Array()
		bCount := 0
		loop (4) {
			this.ButtonTabs.UseTab(A_Index)
			tDDLs := []
			yPos := 304
			loop(8) {
				btnName := "Button " . bCount + A_Index
				this.CreateButtonControls(btnName, 16, yPos, inputCfg.SingleActions, this.CB_EventHandler.Bind(this))
				tDDLs.push(this.window["ddl" . StrReplace(btnName, " ", "_")])
				yPos += 36
			}
			bCount += 8
			this.AllTabDDLs.push(tDDLs)
		}
		
		
		
		this.window.Show()
		SetTimer(this.CB_GetControllerState.Bind(this), 100)
	}
	
	CreateButtonControls(label, x, y, inputsList, callback, selected:=1) {
		name := format("ddl{1}", StrReplace(label, " ", "_"))
		inp := [""]
		inp.push(inputsList*)
		w := 60
		this.window.AddText(format("x{1} y{2} w{3} +Right", x, y+4, w), label)
		this.window.AddDropDownList(format("v{1} x{2} y{3} w224", name, x + 66, y), inp)
		this.window[name].OnEvent("Change", callback)
		this.window[name].Value := selected
	}
	
	CreateHatControls(label, x, y, inputsList, callback, selected:=1) {	
		name := format("ddlHat_{1}", label)
		inp := [""]
		inp.push(inputsList*)
		this.window.AddText(format("x{1} y{2} w60 +Right", x, y+4), label)
		this.window.AddDropDownList(format("v{1} x{2} y{3} w224", name, x + 66, y), inp)
		this.window[name].OnEvent("Change", callback)
		this.window[name].Value := selected
	}
	
	CreateAxisControls(label, x, y, inputsList, callback, selected:=1) {	
		name := format("ddlAxis_{1}", label)
		inp := [""]
		inp.push(inputsList*)
		this.window.AddText(format("x{1} y{2} w60 +Right", x, y+4), label)
		this.window.AddDropDownList(format("v{1} x{2} y{3} w224", name, x + 66, y), inp)
		this.window[name].OnEvent("Change", callback)
		this.window[name].Value := selected
	}
	
	DrawTooltip(msg) {
		X := 0
		Y := 0
		MouseGetPos(&X, &Y)
		ToolTip(msg, X+20, Y)
		SetTimer(() => ToolTip(), -1000) ; clear tooltip timer in 3 sec
	}
	
	CB_MenuHandler(itemName, itemPos, obj) {
		this.window.Opt("+OwnDialogs")
		this.DrawTooltip(itemName ": " itemPos)
	}
	
	CB_ControlListHandler(obj, params*) {
		this.selectedController := this.HardwareIDs[obj.Value]
	}
	
	CB_EventHandler(obj, params*) {
		this.DrawTooltip(obj.Name ": " obj.Value)
	}
	
	CB_GetControllerState() {
		state := this.Controllers[this.selectedController].StateString()
		if (this.window["edtControllerState"].Value != state)
			this.window["edtControllerState"].Value := state
	}
}



;Run the script
config := EGS_InputConfig(EGS_InputConfig_filepath, EGS_ControlProfiles_path)
program := EGSHosasWrapper()
program.Start(config)

