// ActionScript file

//interface controls
private var radioButtonLegend:RadioButton;
private var exportButton:Button;

private function addExportTool(toolObject:ObjectProxy):void {
	
	//make canvas for tool
	var c:Canvas = new Canvas;
	c.label = toolObject.toolLabel; 
	c.width = toolsAccordion.width;
	c.height = toolsAccordion.height;
	c.name = toolObject.toolName;
	c.id = toolObject.toolName + "Canvas";
	
	//add radio buttons for item to export
	var llabel:Label = new Label;
	llabel.text = "Select an item to export.";
	llabel.id = toolObject.toolName + "Label3";
	llabel.y=5;
	llabel.x=2;
	//llabel.styleName="toolLabel";
	c.addChild(llabel);
	
	radioButtonMap = new RadioButton;
	radioButtonMap.label = "Export Map";
	radioButtonMap.groupName = "PrintItem";
	radioButtonMap.x=2;
	radioButtonMap.y=25;
	radioButtonMap.selected = true;
	c.addChild(radioButtonMap);
	
	radioButtonLegend = new RadioButton;
	radioButtonLegend.label = "Export Legend";
	radioButtonLegend.groupName = "PrintItem";
	radioButtonLegend.x=112;
	radioButtonLegend.y=25;
	c.addChild(radioButtonLegend);
	
	//add print button
	exportButton = new Button;
	exportButton.label = "Export"
	exportButton.x=2;
	exportButton.y=55;
	exportButton.addEventListener(MouseEvent.CLICK, exportMap);
	c.addChild(exportButton);
	
	//add canvas to accordion
	toolsAccordion.addChild(c);
}

private function exportMap(evt:MouseEvent):void {
	
	//hide extra map stuff
	theMap.zoomSliderVisible = false;
	
	//export map
	if (radioButtonMap.selected) {
		exportMapToPNG();
	}
	else if (radioButtonLegend.selected) {
		exportLegendToPNG();
	}
	
	//restore map
	theMap.zoomSliderVisible = true;
}	

private function exportMapToPNG():void {
	cursorManager.setBusyCursor();  
	
	//hide extra map stuff
	theMap.zoomSliderVisible = false;
	
	//save map to image
	var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
	var pngURLRequest:URLRequest = new URLRequest("php/pngMapCreate.php?name=userMap.png");
	pngURLRequest.requestHeaders.push(header);
	pngURLRequest.method = URLRequestMethod.POST;
	pngURLRequest.data = getMap();
	navigateToURL(pngURLRequest, "_blank");
	
	//restore map
	theMap.zoomSliderVisible = true;
	cursorManager.removeBusyCursor();
}

private function getMap():ByteArray {
	var bitmapdata:BitmapData = new BitmapData(theMap.width, theMap.height, false, 0xFFFFFF);
    bitmapdata.draw(theMap);
    var pngEncoder:PNGEncoder = new PNGEncoder();
    var bytes:ByteArray = pngEncoder.encode(bitmapdata);
    return bytes;
}

private function exportLegendToPNG():void {
	cursorManager.setBusyCursor();  
	
	//save legend  to image
	var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
	var pngURLRequest:URLRequest = new URLRequest("php/pngLegendCreate.php?name=userLegend.png");
	pngURLRequest.requestHeaders.push(header);
	pngURLRequest.method = URLRequestMethod.POST;
	pngURLRequest.data = getLegend();
	navigateToURL(pngURLRequest, "_blank");

	cursorManager.removeBusyCursor();
}

private function getLegend():ByteArray {
	var bitmapdata:BitmapData = new BitmapData(legendCanvas.width, legendCanvas.height, true);
    bitmapdata.draw(legendCanvas);
    var pngEncoder:PNGEncoder = new PNGEncoder();
    var bytes:ByteArray = pngEncoder.encode(bitmapdata);
    return bytes;
}





