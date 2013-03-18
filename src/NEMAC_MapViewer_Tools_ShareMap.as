// ActionScript file
private var urlTextArea:mx.controls.TextArea;

private function addShareMapTool(toolObject:ObjectProxy):void {
	//make canvas for tool
	var c:Canvas = new Canvas;
	c.label = toolObject.toolLabel; 
	c.width = toolsAccordion.width;
	c.height = toolsAccordion.height;
	c.name = toolObject.toolName;
	c.id = toolObject.toolName + "Canvas";

	//add label to canvas
	var helpTextArea:mx.controls.TextArea = new mx.controls.TextArea;
	helpTextArea.text = toolObject.helpText;
	helpTextArea.y=5;
	helpTextArea.x=2;
	helpTextArea.editable = false;
	helpTextArea.width = c.width * 0.95;
	helpTextArea.height = 40;
	c.addChild(helpTextArea);
	
	//add text box to show share URL
	urlTextArea = new mx.controls.TextArea;
	urlTextArea.text = '';
	urlTextArea.y=50;
	urlTextArea.x=2;
	urlTextArea.editable = false;
	urlTextArea.width = c.width * 0.95;
	urlTextArea.height = 270;
	c.addChild(urlTextArea);

	//add canvas to accordion
	toolsAccordion.addChild(c);
	
}

private function setShareURL():void {
	getShareURL();
	urlTextArea.text = currentShareURL;
}

private function getShareURL():void {
	
	//start string with current map view
  /*xxxx
    var urlString:String = 'http://ews.forestthreats.org/gis/ews_gis.html?theme='+ mapViewMenu.selectedItem.name;
    xxxx*/
    var urlString:String = this.htmlPageURL + '?theme=' + mapViewMenu.selectedItem.name;

	//get visible layers and their alphas
	var layerString:String = '';
	var alphaString:String = '';
	for (var i:uint=0; i<theMapLayers.length; i++) {
    	if ((theMapLayers[i].visible == true) && (theMapLayers[i].id != "timeSliderLayer")) {

/*xxxx
    		layerString = layerString + theMapLayers[i].mapId + ","
xxxx*/
    		layerString = layerString + theMapLayers[i].lid + ",";
				
			// The following is a workaround for the problem related to NaN values showing up in
			// the share URL string when the app was launched from a share URL.  Apparently that
			// problem results from theMapLayers[i].transparency sometimes not being correctly
			// initialized, so we fix the issue here by checking to make sure that it has been
			// given a value that is a number, and if not, initialize it to 0.  (The correct solution
			// would be to find the place in the code where it should have been initialized in the first
			// place and fix it there.)
			if (!(theMapLayers[i].transparency is Number)) {
				theMapLayers[i].transparency = 0;
			}
			
    		alphaString = alphaString + String(1.0 - (theMapLayers[i].transparency/100)) + ","
    	}
    }
    // do not remove trailing comma - needed to prevent layer111 from turning on layer1, layer 11

	urlString = urlString + "&layers=" + layerString;
	urlString = urlString + "&alphas=" + alphaString;

	urlString = urlString + "&accgp=" + layerAccordion.selectedChild.name.replace(/_Canvas$/, '');  // chop "_Canvas" from end of name!!!
	
	//get current basemap
	urlString = urlString + "&basemap=" + backgroundImageMenu.selectedItem.name;
	
	//if multigraph is shown, add that - ONLY SHOWS MOST RECENTLY OPENED GRAPH
	//urlString = urlString + "&multigraph=" + multigraphXCoord.text + "," + multigraphYCoord.text;
	
	//get current extent
	urlString = urlString + "&extent=" + theMap.extent.xmin + "," + theMap.extent.ymin + "," + theMap.extent.xmax + "," + theMap.extent.ymax;
	
	//show string
	currentShareURL = urlString;
	
}
