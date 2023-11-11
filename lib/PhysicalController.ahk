#Requires AutoHotkey v2.0
#include "JoyGetDevCapsWrapper.ahk"

; Name: Controller.ahk
; Desc: Controller object. 
	;maps degree-based discrete hat input to +1/0/-1 x and y inputs
_discreteHatMap := Map()
_discreteHatMap[-1]		:= {x:0 , y:0 }
_discreteHatMap[0]		:= {x:0 , y:1 }
_discreteHatMap[4500]	:= {x:1 , y:1 }
_discreteHatMap[9000]	:= {x:1 , y:0 }
_discreteHatMap[13500]	:= {x:1 , y:-1}
_discreteHatMap[18000]	:= {x:0 , y:-1}
_discreteHatMap[22500]	:= {x:-1, y:-1}
_discreteHatMap[27000]	:= {x:-1, y:0 }
_discreteHatMap[31500]	:= {x:-1, y:1 }


class PhysicalController {
	
	static RegistryLocation := "HKEY_CURRENT_USER\SYSTEM\CurrentControlSet\Control\MediaProperties\PrivateProperties\Joystick\OEM\"
	
	;CONSTRUCTOR
	__New(joyNum) {
		;store AHK joyNum
		this._ahkJoyID := joyNum
		;parse NJoyInfo string for available axes
		;X and Y axes always exist so add them to the
		;front of the string for easier iteration
		this._aAxes := "XY" . GetKeyState(joyNum . "JoyInfo")
		;extract hat info if present
		if (InStr(this._aAxes, "P")) {
			this._aAxes := StrReplace(this._aAxes, "P")
			this._hatInfo .= "P"
			if (InStr(this._aAxes, "D")) {
				this._aAxes := StrReplace(this._aAxes, "D")
				this._hatInfo .= "D"
			}
			else if (InStr(this._aAxes, "C")) {
				this._aAxes := StrReplace(this._aAxes, "C")
				this._hatInfo .= "C"
			}
		}
		
		this._buttonNames := []
		loop (this.ButtonCount) {
			this.ButtonNames[A_Index] := this._ahkJoyID . "Joy" . A_Index
		}
	}
	
	;PROPERTIES
	;get this controller's joyID
	JoyID => this._ahkJoyID
	
	;get the registry key
	RegKey => Format("{1}VID_{2:04X}&PID_{3:04X}\", PhysicalController.RegistryLocation, JoyGetDevCaps.GetPropValue(this._ahkJoyID, "wMid"), JoyGetDevCaps.GetPropValue(this._ahkJoyID, "wPid"))
	
	;get the registry OEM Name
	Name => RegRead(this.RegKey, "OEMName", "unknown controller")
	
	HasHat => InStr(this._hatInfo, "P")
	
	HasContinuousHat => InStr(this._hatInfo, "C")
	
	ButtonCount => GetKeyState(this._ahkJoyID . "JoyButtons")
	
	
	;outputs an object that holds the current axis, hat and button states for this controller  
	State {
		get {
			axStates := []
			; loop parse each char and get existing axis state
			loop Parse, this._aAxes
				axStates.push({%A_LoopField%: GetKeyState(this._ahkJoyID . "Joy" . A_LoopField)})
				
			;Hat input
			hatState := (!this.HasHat) 
				? -1 
				: (this.HasContinuousHat ? GetKeyState(this._ahkJoyID . "JoyPOV") : _discreteHatMap[GetKeyState(this._ahkJoyID . "JoyPOV")]) 
			
			bHeld := []
			loop (this.ButtonCount)
				if (GetKeyState(this._ahkJoyID . "Joy" . A_Index))
					bHeld.push(A_Index)
			
			return { Axes: axStates, Hat: hatState, Buttons: bHeld }
		}
	}
	
	
	; Bind buttons as hotkeys
	BindButtons(bKeys) {
		this._buttonKeys := []
		for (butNm in this._buttonNames) {
			if (bKeys.%butNm% != "") {
				this._buttonKeys[A_Index] := bKeys.%butNm%
				Hotkey(buttonName, Func(this.Callback_ButtonPress).Bind(A_Index))
			}
		}
	}
	
	Callback_ButtonPress(btn){
		;Sends mapped key down state then wait
		;for button release to send key up state
		EGSInterface.PressKey(this._buttonKeys[btn])
		
		while(GetKeyState(this._buttonNames[btn]))
			Sleep(10)
			
		EGSInterface.ReleaseKey(this._buttonKeys[btn])
	}
}