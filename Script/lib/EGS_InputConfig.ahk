#Requires AutoHotkey v2.0
#include "InputMaps.ahk"

class EGS_InputConfig {	
	SingleActions := Array()
	AxisActions := Array()
	InputMap := Array()
	ControlProfiles := Array()
	
	__New(controlMapFilename, profileDir) {
		
		XMLDocument := ComObject("MSXML2.DOMDocument.6.0")
        XMLDocument.Async := false
		
		;Load EGS control map file and mapped to AHK inputActionID
		XMLDocument.LoadXML(FileRead(controlMapFilename))
		
		for (entry in XMLDocument.getElementsByTagName("MapInfo")) {
			innerXML := RegExReplace(entry.selectSingleNode("xml").text, "xmlns=`".*?`"", "")
			XMLDocument.LoadXML(innerXML)
			
			for (action in XMLDocument.getElementsByTagName("ActionElementMap")) {	
				aID := Integer(action.selectSingleNode("actionId").text)
				axisCont :=Integer(action.selectSingleNode("axisContribution").text)	
				
				isMouse := XMLDocument.selectSingleNode("MouseMap")		
				actID := Integer(action.selectSingleNode(isMouse ? "elementIdentifierId" : "keyboardKeyCode").text)
				this.InputMap.push({
					egsActionName: ActionNameMapEGS[format("{1},{2}", aID, axisCont)],
					isMouseAction: isMouse,
					ahkInput: isMouse ? MouseMapEGSToAHK[actID] : KeyMapEGSToAHK[actID]
				})
			}
		}
		
		loop files profileDir . "*.xml" {
			XMLDocument.LoadXML(FileRead(A_LoopFilePath))
			profileDef := XMLDocument.selectSingleNode("ControlMap")
			buttonMap := Map()
			for (buttonNode in profileDef.selectSingleNode("Buttons").childNodes)
				buttonMap[buttonNode.nodeName] := buttonNode.text
				
			axes := {}
			for (axisNode in profileDef.selectSingleNode("GameAxes").childNodes) {
				gInputNode := axisNode.selectSingleNode("GameInput")
				if (gInputNode.GetAttribute("type") == "mouseAxis")
					inputActionID := gInputNode.text 
				else
					inputActionID := { 
						pos: gInputNode.selectSingleNode("pos").text, 
						neg: gInputNode.selectSingleNode("neg").text 
					}
					
				modTime := axisNode.selectSingleNode("SendModulationTime")		
				sendRatio := axisNode.selectSingleNode("MinSendDurationRatio")
					
				cMap := axisNode.selectSingleNode("ControllerMap")
				axes.%axisNode.nodeName% := {
					GameInput: inputActionID,
					SendModulationTime: modTime ? Float(modTime.text) : 0,
					MinSendDurationRatio: sendRatio ? Float(sendRatio.text) : 0,
					ControllerMap: {
						HardwareID:		cMap.selectSingleNode("HardwareID"),
						AxisID:			cMap.selectSingleNode("AxisID"),
						Sensitivity: 	Float(cMap.selectSingleNode("Sensitivity").text),
						Deadzone: 		Float(cMap.selectSingleNode("Deadzone").text),
						Inverted:		IsObject(cMap.selectSingleNode("Inverted")) ? cMap.selectSingleNode("Inverted").text == "true": false
					}
				}
			}
				
			this.ControlProfiles.push({
				ProfileID: Integer(profileDef.selectSingleNode("ProfileID").text),
				Buttons: buttonMap,
				GameAxes: axes
			})
		}
		
		for (k, v in ActionNameMapEGS) {
			this.SingleActions.push(v)
		}
	}
}