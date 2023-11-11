#Requires AutoHotkey v2.0

class XMLFile {
	__New(filename) {
		this.xmlFilename := filename
		this.XmlComObj := ComObject("MSXML2.DOMDocument.6.0")
        this.XmlComObj.Async := false
	}
}