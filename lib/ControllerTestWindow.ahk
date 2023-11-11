#Requires AutoHotkey v2.0
#include "PhysicalController.ahk"
; Name: ControllerTester.ahk
; Desc: Controller Test Window. Polls given controller object's state and outputs to a test window.

class ControllerTestWindow {
	_guiTestWindow := {}
	_edtContInputView := {}
	
	__New() {
		this._guiTestWindow := Gui("+AlwaysOnTop", "<No joyID>", this)
		this._edtContInputView := this._guiTestWindow.AddEdit("w350 r3 +ReadOnly")
	}
	
	Show(contObj) {
		this._guiTestWindow.Title := "Testing " . contObj.Name
		this._guiTestWindow.Show()
		
		this.PollControllerState(contObj)
	}

	PollControllerState(cont)
	{	
		loop {
			;cache property
			contState := cont.State
			
			;print current axis state
			stateStr := "Axes:" . A_Tab
			loop (contState.Axes.Length) {
				axis := contState.Axes[A_Index]
				for (k, v in axis.OwnProps())
					stateStr .= k . ":" . Format("{1:03i}", v) . A_Space . A_Space
			}
			stateStr .= "`nHat:" . A_Tab . (cont.HasContinuousHat ? contState.Hat : "x:" . contState.Hat.x . A_Space . A_Space . "y:" . contState.Hat.y)
			
			;only print if buttons are present	
			if (cont.ButtonCount > 0)
				stateStr .= "`nButtons(" . cont.ButtonCount . "): " . A_Tab . "Pressed: "
			;print each held button number	
			For (bNum in contState.Buttons)
				stateStr .= bNum . A_Space . A_Space
			
			;output result to gui
			this._edtContInputView.Value := stateStr
			
			;wait 100ms
			Sleep(100)
		}
	}
}