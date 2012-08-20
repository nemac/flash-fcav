// ActionScript file

//interface controls
private var printComboBox:ComboBox;
private var radioButtonPortrait:RadioButton;
private var radioButtonLandscape:RadioButton;
private var radioButtonMap:RadioButton;
private var radioButtonPDF:RadioButton;
private var radioButtonPNG:RadioButton;
private var printButton:Button;
private var previewButton:Button;
private var restoreButton:Button;
private var titleTextBox:TextInput;

//map settings
private var origMapCenter:MapPoint;
private var origMapWidth:Number;
private var origMapHeight:Number;
private var origMapExtent:Extent;
private var newPageWidth:Number;
private var newPageHeight:Number;

//PDF object settings
private var printPDF:PDF; //PDF page object
private var marginRect:Rectangle;
private var pageWidth:Number;
private var pageHeight:Number;
private var sideMargin:Number;
private var topMargin:Number;
private var topSpace:Number = 80;
private var bottomSpace:Number = 40;

private function addPrintTool(toolObject:ObjectProxy):void {
	
	//make canvas for tool
	var c:Canvas = new Canvas;
	c.label = toolObject.toolLabel; 
	c.width = toolsAccordion.width;
	c.height = toolsAccordion.height;
	c.name = toolObject.toolName;
	c.id = toolObject.toolName + "Canvas";
	
	//add size combobox to canvas
	var llabel:Label = new Label;
	llabel.text = "Select a print size.";
	llabel.id = toolObject.toolName + "Label1";
	llabel.x=2;
	llabel.y=5;
	//llabel.styleName="toolLabel";
	c.addChild(llabel);
	
	printComboBox = new ComboBox;
	printComboBox.dataProvider = [
                {name: "Letter", size:"LETTER"},
                {name: "Legal", size:"LEGAL"},
                {name: "Tabloid", size:"TABLOID"}
                	];
	printComboBox.labelField="name";
	printComboBox.selectedIndex = 0;
	printComboBox.id = toolObject.toolName + "ComboBox";
	printComboBox.x=122;
	printComboBox.y=5;
	printComboBox.width=75;
	c.addChild(printComboBox);
	
	//add radio buttons for orientation
	llabel = new Label;
	llabel.text = "Select an orientation.";
	llabel.id = toolObject.toolName + "Label2";
	llabel.x=2;
	llabel.y=35;
	//llabel.styleName="toolLabel";
	c.addChild(llabel);
	
	radioButtonLandscape = new RadioButton;
	radioButtonLandscape.label = "Landscape";
	radioButtonLandscape.groupName = "Orientation";
	radioButtonLandscape.x=2;
	radioButtonLandscape.y=55;
	radioButtonLandscape.selected = true;
	c.addChild(radioButtonLandscape);
	
	radioButtonPortrait = new RadioButton;
	radioButtonPortrait.label = "Portrait";
	radioButtonPortrait.groupName = "Orientation";
	radioButtonPortrait.x=112;
	radioButtonPortrait.y=55;
	c.addChild(radioButtonPortrait);
	
	//add title entry
	llabel = new Label;
	llabel.text = "Title:";
	llabel.id = toolObject.toolName + "TitleLabel";
	llabel.x=2;
	llabel.y=85;
	c.addChild(llabel);
	
	titleTextBox = new TextInput;
	titleTextBox.text = "Title"
	titleTextBox.x = 2;
	titleTextBox.y = 105;
	titleTextBox.width = 200;
	titleTextBox.maxChars = 100;
	c.addChild(titleTextBox);
	
	//add preview button
	previewButton = new Button;
	previewButton.label = "Print Preview"
	previewButton.x=2;
	previewButton.y=135;
	previewButton.addEventListener(MouseEvent.CLICK, openMapPrintWindow);
	c.addChild(previewButton);
	
	/*//add restore map button
	restoreButton = new Button;
	restoreButton.label = "Restore Map"
	restoreButton.x=112;
	restoreButton.y=135;
	restoreButton.addEventListener(MouseEvent.CLICK, restoreMap);
	restoreButton.enabled = false;
	c.addChild(restoreButton);
	
	//add print button
	printButton = new Button;
	printButton.label = "Print Map"
	printButton.x=2;
	printButton.y=165;
	printButton.addEventListener(MouseEvent.CLICK, printMap);
	printButton.enabled = false;
	c.addChild(printButton);*/
	
	//add canvas to accordion
	toolsAccordion.addChild(c);

}

private function resizeMapForPrinting(strSize:String, strOrientation:String):void {
	
	//save map settings
	origMapCenter = theMap.extent.center;
	origMapExtent = theMap.extent;
	
	//save map size
	origMapWidth = theMap.width;
	origMapHeight = theMap.height

	//create page size
	var theSize:Size;
	if (strSize == "Tabloid") {
		theSize = Size.TABLOID;
	}
	else if (strSize == "Legal") {
		theSize = Size.LEGAL;
	}
	else {
		theSize = Size.LETTER;
	}
	
	//create page orientation
	var theOrientation:String;
	if (strOrientation == "Portrait") {
		theOrientation = Orientation.PORTRAIT;
	}
	else {
		theOrientation = Orientation.LANDSCAPE;
	}
	
	//make PDF and add page
	printPDF = new PDF(theOrientation, Unit.POINT, theSize );
	printPDF.addPage();
	
	//get margins so we can get current page size
	marginRect = printPDF.getMargins();
	pageWidth = marginRect.right - marginRect.left;
	pageHeight = marginRect.bottom - marginRect.top;
	sideMargin = pageWidth*0.02;
	topMargin = pageHeight*0.02;
	
	//now set margins to 2% of dimensions and get margins agsin
	printPDF.setMargins(sideMargin, topMargin, sideMargin, topMargin);
	marginRect = printPDF.getMargins();
	pageWidth = marginRect.right - marginRect.left;
	pageHeight = marginRect.bottom - marginRect.top;
	
	//resize the map to match the needed aspect ratio
	newPageHeight = dp0.height*0.90;
	newPageWidth = (newPageHeight*pageWidth)/pageHeight;
	
	theMap.height = newPageHeight// - topSpace - bottomSpace; //reserve room for logos and text
	theMap.width = newPageWidth;
	theMap.addEventListener(ExtentEvent.EXTENT_CHANGE, extentChangeMapHandler1);

}

/*
private function previewMap(evt:MouseEvent):void {
	
	//save map settings
	origMapCenter = theMap.extent.center;
	origMapExtent = theMap.extent;
	
	//save map size
	origMapWidth = theMap.width;
	origMapHeight = theMap.height

	//create page size
	var theSize:Size;
	if (printComboBox.selectedLabel == "Tabloid") {
		theSize = Size.TABLOID;
	}
	else if (printComboBox.selectedLabel == "Legal") {
		theSize = Size.LEGAL;
	}
	else {
		theSize = Size.LETTER;
	}
	
	//create page orientation
	var theOrientation:String;
	if (radioButtonPortrait.selected) {
		theOrientation = Orientation.PORTRAIT;
	}
	else {
		theOrientation = Orientation.LANDSCAPE;
	}
	
	//make PDF and add page
	printPDF = new PDF(theOrientation, Unit.POINT, theSize );
	printPDF.addPage();
	
	//get margins so we can get current page size
	marginRect = printPDF.getMargins();
	pageWidth = marginRect.right - marginRect.left;
	pageHeight = marginRect.bottom - marginRect.top;
	sideMargin = pageWidth*0.02;
	topMargin = pageHeight*0.02;
	
	//now set margins to 2% of dimensions and get margins agsin
	printPDF.setMargins(sideMargin, topMargin, sideMargin, topMargin);
	marginRect = printPDF.getMargins();
	pageWidth = marginRect.right - marginRect.left;
	pageHeight = marginRect.bottom - marginRect.top;
	
	//resize the map to match the needed aspect ratio
	newPageHeight = dp0.height*0.90;
	newPageWidth = (newPageHeight*pageWidth)/pageHeight;
	
	theMap.height = newPageHeight// - topSpace - bottomSpace; //reserve room for logos and text
	theMap.width = newPageWidth;
	theMap.addEventListener(ExtentEvent.EXTENT_CHANGE, extentChangeMapHandler1);
		
	//allow printing
	previewButton.enabled = false;
	restoreButton.enabled = true;
	printButton.enabled = true;
}
*/

private function extentChangeMapHandler1(evt:ExtentEvent):void {
	theMap.removeEventListener(ExtentEvent.EXTENT_CHANGE, extentChangeMapHandler1);
	
	if (theMap.loaded) {
		if (areaAC.selectedItem == null) {
			setMapExtent(theDefaultMapZoomID);
		}
		else {
			setMapExtent(areaAC.selectedItem.areaID);
		}	
	}	
	theMap.extent = theMap.extent.expand(1.00001);
}

private function openMapPrintWindow(evt:MouseEvent):void {
	//create shared URL
	getShareURL(); //sets currentShareURL global variable
	currentShareURL = currentShareURL + "&state=Print&print=" + printComboBox.selectedLabel;
	if (radioButtonPortrait.selected) {
		currentShareURL = currentShareURL + ",Portrait";
	} 
	else {
		currentShareURL = currentShareURL + ",Landscape";
	}
	currentShareURL = currentShareURL + "&title=" + titleTextBox.text.replace(" ", "_");
	
	var myURL:URLRequest = new URLRequest(currentShareURL); 
	navigateToURL(myURL, "_blank");
}

private function printMap(evt:MouseEvent):void {
	cursorManager.setBusyCursor();
	printToPDF();
	
}

private function printToPDF():void {
	cursorManager.setBusyCursor();
	theMap.zoomSliderVisible = false;
	//printButton.enabled = false;
	var spacerOffset:uint = 1;
	
	//draw neat line
	printPDF.textStyle(new RGBColor(0x00000), 1, 0, 0, 0, 100, 0);
	printPDF.drawRect(new Rectangle(sideMargin, topMargin, pageWidth, pageHeight));
	
	//add map
	printPDF.addImage(theMap, null, spacerOffset, spacerOffset, pageWidth-(2*spacerOffset), pageHeight-(2*spacerOffset), 0, 0.8, true, "JPG", 100);
	
	//add title
	printPDF.textStyle(new RGBColor(0x00000), 1, 0, 0, 0, 100, 0);
	printPDF.setFontSize(24); 
	printPDF.addText(sharedPrintTitle.replace("_", " "), sideMargin+10, topMargin+20);
	
	//add TACCIMO logo
	//printPDF.addImageStream(new pngTACCIMOLogo as ByteArray, '', null, marginRect.right-200-sideMargin-spacerOffset, marginRect.top-10, 200, 58.1, 0, 0.8, 'normal', null);
	
	//add legend
	printPDF.addImage(legendCanvas, null, (sideMargin+(2*spacerOffset)), pageHeight-(legendCanvas.height*0.5)-50, legendCanvas.width*0.5, legendCanvas.height*0.5, 0, 0.8, true, "JPG", 100);
	
	//add source
	//printPDF.setFontSize(12); 
	//printPDF.addText(getMetadata('dataSources'), sideMargin+150, pageHeight-topMargin);
	
	//add date
	printPDF.setFontSize(10); 
	printPDF.addText(getCurrentDate(), sideMargin+150, pageHeight);
	
	//add USFS and EFETAC logos
	//printPDF.addImageStream(new pngUSFSLogo as ByteArray, '', null, pageWidth-60-spacerOffset, pageHeight-64.1-62-spacerOffset-20, 60, 64.1, 0, 0.8, 'normal', null);
	//printPDF.addImageStream(new pngEFETACLogo as ByteArray, '', null, pageWidth-60-spacerOffset, pageHeight-62-spacerOffset-20, 60, 62, 0, 0.8, 'normal', null);
	
	//add web site
	//printPDF.addText(getMetadata('webSite'), pageWidth-sideMargin-135, pageHeight+(5*spacerOffset));
	
	//save map and open
	//printPDF.save( Method.REMOTE, "pdfCreator.cfm", Download.INLINE, "map.pdf" );
	printPDF.save( Method.REMOTE, "php/pdfCreate.php", Download.ATTACHMENT, "map.pdf" );
	
}

private function restoreMap(evt:MouseEvent):void {
	theMap.zoomSliderVisible = true;
	theMap.width = origMapWidth;
	theMap.height = origMapHeight;
	theMap.addEventListener(ExtentEvent.EXTENT_CHANGE, extentChangeMapHandler1);
	
	previewButton.enabled = true;
	restoreButton.enabled = false;
	printButton.enabled = false;
	
	currentState= "";
}


