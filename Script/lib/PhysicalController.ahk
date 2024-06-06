#Requires AutoHotkey v2.0
#include "JoyGetDevCapsWrapper.ahk"
#include "EGS_Interface.ahk"

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
		this.VID := JoyGetDevCaps.GetPropValue(this._ahkJoyID, "wMid")
		this.PID := JoyGetDevCaps.GetPropValue(this._ahkJoyID, "wPid")
		;parse NJoyInfo string for available axes
		;X and Y axes always exist so add them to the
		;front of the string for easier iteration
		this._aAxes := "XY" . GetKeyState(joyNum . "JoyInfo")
		;extract hat info if present
		this._hatInfo := ""
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
		loop (this.ButtonCount)
			this._buttonNames.push(this._ahkJoyID . "Joy" . A_Index)
	}
	
	;PROPERTIES
	JoyID => this._ahkJoyID
	HardwareID => this.VID . "::" . this.PID
	
	;get the registry key
	RegKey => Format("{1}VID_{2:04X}&PID_{3:04X}\", PhysicalController.RegistryLocation, this.VID, this.PID)
	
	Name => RegRead(this.RegKey, "OEMName", "unknown controller")
	
	ShortName(len) {
		name := this.Name
		return strlen(name) > len ? Format("{1}...", trim(substr(name, 1, len))) : name
	}
	
	HasHat => InStr(this._hatInfo, "P")
	
	HasContinuousHat => InStr(this._hatInfo, "C")
	
	ButtonCount => GetKeyState(this._ahkJoyID . "JoyButtons")
	
	;outputs an object that holds the current axis, hat and button states for this controller  
	State => { Axes: this.AxesState, Hat: this.HatState, Buttons: this.ButtonState }
	
	AxesState {
		get {
			axStates := []
			; loop parse each char and get existing axis state
			loop Parse, this._aAxes
				axStates.push({%A_LoopField%: GetKeyState(this._ahkJoyID . "Joy" . A_LoopField)})
			return axStates
		}
	}
	
	HatState {
		get {
			if this.HasHat {
				rawState := GetKeyState(this._ahkJoyID . "JoyPOV")
				if this.HasContinuousHat 
					return rawState
				else
					return _discreteHatMap[rawState]
			}
			return _discreteHatMap[-1]
		}
	}
	
	ButtonState {
		get {
			bHeld := []
			loop (this.ButtonCount)
				if (GetKeyState(this._ahkJoyID . "Joy" . A_Index))
					bHeld.push(A_Index)
			return bHeld
		}	
	}
	
	; Bind buttons as hotkeys
	BindButtons(bKeys) {
		this._buttonKeys := []
		for (btnNm in this._buttonNames) {
			if (bKeys.%btnNm% != "") {
				this._buttonKeys[A_Index] := bKeys.%btnNm%
				Hotkey(btnNm, Func(this.Callback_ButtonPress).Bind(A_Index))
			}
		}
	}
	
	Callback_ButtonPress(btn){
		;Sends mapped key down state then wait
		;for button release to send key up state
		EGS_Interface.PressKey(this._buttonKeys[btn])
		
		while(GetKeyState(this._buttonNames[btn]))
			Sleep(10)
			
		EGS_Interface.ReleaseKey(this._buttonKeys[btn])
	}
	
	StateString() {
		stateStr := Format("{1} ({2})`nAxes:`t", this.ShortName(20), this.HardwareID)
		
		;print current axis state
		loop (this.State.Axes.Length) {
			axis := this.State.Axes[A_Index]
			for (k, v in axis.OwnProps())
				stateStr .= Format("{1}:{2:03i}  ", k, v)
		}
		
		if (this.HasContinuousHat) 
			stateStr .= Format("`nHat:`t{1}", this.State.Hat)
		else
			stateStr .= Format("`nHat:`tx:  {1} y:  {2}", this.State.Hat.x, this.State.Hat.y)
			
		;only print if buttons are present	
		if (this.ButtonCount > 0) {
			stateStr .= Format("`nButtons({1}) Pressed: ", this.ButtonCount)
			;print each held button number	
			for (bNum in this.State.Buttons)
				stateStr .= Format("{1}  ", bNum)
		}
		return stateStr
	}
}