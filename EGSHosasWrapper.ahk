#Requires AutoHotkey v2.0
#SingleInstance Force
#include "lib\PhysicalController.ahk"
#include "lib\ControllerTestWindow.ahk"

class EGSHosasWrapper {
	_ActiveControllers := []
	__New() {
		;Query for each possible (1 to 16) controller id and 
		;create controller objects for all that are found/active.
		loop (16) {
			if this.ControllerIDActive(A_Index)
				this._ActiveControllers.push(PhysicalController(A_Index))
		}
	}
	
	Count => this.ActiveIDs.Length() 

	ControllerIDActive(cID) {
		;check for controller presence by querying AHK joy name
		return GetKeyState(cID . "JoyName") != ""
	}
	
	AllActiveNames() { 
		ret := []
		loop (this.Count)
			ret.push(this._ActiveControllers[A_Index].Name)
		return ret
	}
	
	AllActiveIDs() { 
		ret := []
		loop (this.Count)
			ret.push(this._ActiveControllers[A_Index].JoyID)
		return ret
	}
	
	StartScript() {
		;for testing
		ControllerTestWindow().Show(this._ActiveControllers[1])
	}
	
}


;Run the script
program := EGSHosasWrapper()
program.StartScript()