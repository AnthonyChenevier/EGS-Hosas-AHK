#Requires AutoHotkey v2.0
;EXAMPLE
;SetBatchLines, -1
;NumDevs := DllCall("Winmm.dll\joyGetNumDevs", "UInt")
;MsgBox, 0, NumDevs, %NumDevs%
;loop, %NumDevs%
;{
;	nm := GetPropValue(A_Index, "szPname")
;	if (nm && nm != "ERR") {
;		MsgBox, 0, %A_Index%Joy device name, %nm%
;	}
;}
;ExitApp
class JoyGetDevCapsWrapper {
	;typedef struct {
	;  WORD  wMid;
	;  WORD  wPid;
	;  TCHAR szPname[MAXPNAMELEN];
	;  UINT  wXmin;
	;  UINT  wXmax;
	;  UINT  wYmin;
	;  UINT  wYmax;
	;  UINT  wZmin;
	;  UINT  wZmax;
	;  UINT  wNumButtons;
	;  UINT  wPeriodMin;
	;  UINT  wPeriodMax;
	;  UINT  wRmin;
	;  UINT  wRmax;
	;  UINT  wUmin;
	;  UINT  wUmax;
	;  UINT  wVmin;
	;  UINT  wVmax;
	;  UINT  wCaps;
	;  UINT  wMaxAxes;
	;  UINT  wNumAxes;
	;  UINT  wMaxButtons;
	;  TCHAR szRegKey[MAXPNAMELEN];
	;  TCHAR szOEMVxD[MAX_JOYSTICKOEMVXDNAME];
	;} JOYCAPS;
	
	;m= propName:		offset, type
	static JOYCAPS_MemberData := {
		wMid:       	[0  ,  "uShort"],
		wPid:       	[2  ,  "uShort"],
		szPname:    	[4  ,  "UTF-16"],
		wXmin:      	[36 ,  "uInt"],
		wXmax: 			[40 ,  "uInt"],
		wYmin: 			[44 ,  "uInt"],
		wYmax: 			[48 ,  "uInt"],
		wZmin: 			[52 ,  "uInt"],
		wZmax: 			[56 ,  "uInt"],
		wNumButtons: 	[60 ,  "uInt"],
		wPeriodMin: 	[64 ,  "uInt"],
		wPeriodMax: 	[68 ,  "uInt"],
		wRmin: 			[72 ,  "uInt"], 
		wRmax: 			[76 ,  "uInt"],
		wUmin: 			[80 ,  "uInt"], 
		wUmax: 			[84 ,  "uInt"],
		wVmin: 			[88 ,  "uInt"],
		wVmax: 			[92 ,  "uInt"],
		wCaps: 			[96 ,  "uInt"], 
		wMaxAxes: 		[100,  "uInt"],
		wNumAxes: 		[104,  "uInt"],
		wMaxButtons: 	[108,  "uInt"],
		szRegKey: 		[112,  "UTF-16"],
		szOEMVxD: 		[144,  "UTF-16"],
	}
	
	;based on: https://www.autohotkey.com/board/topic/87509-oem-joystick-name/
	GetPropValue(joyNum, propName) {
		if (joyNum < 1 || joyNum > 16) {
			msgbox("joyNum " . joyNum . " is an invalid parameter for GetJoyProperty`nValid numbers are 1 to 16", 48)
			return 0
		}
		
		propOffset := JoyGetDevCapsWrapper.JOYCAPS_MemberData.%propName%[1]
		propType := JoyGetDevCapsWrapper.JOYCAPS_MemberData.%propName%[2]
		
		if (propOffset < 0) {
			msgbox("Property '" . propName . "' is an invalid parameter for GetJoyProperty", 48)
			return 0
		}
			
		jcStructVar := Buffer(728, 0)
		if !dllcall("winmm\joyGetDevCapsW", "uInt",joyNum-1, "Ptr", jcStructVar, "uInt", jcStructVar.Size)
			return (SubStr(propName, 1, 2) = "sz") ;is a string
				? StrGet(jcStructVar.Ptr+propOffset, propType) 
				: NumGet(jcStructVar, propOffset, propType)
		
		;Failed to read JOYCAPS struct
		return 0
	}

	;get all joycaps props for the given controller id
	AllPropsString(joyNum) {
		res := ""
		for (propName,_ in JoyGetDevCapsWrapper.JOYCAPS_MemberData)
			res .= propName . ": " . this.GetPropValue(joyNum, propName) . "`n"
		return res	
	}
}

;create a global instance
JoyGetDevCaps := JoyGetDevCapsWrapper()

