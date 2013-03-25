// ActionScript file
private var multigraphGraphicsLayer:GraphicsLayer; //layer for showing results  
private var multigraphPoint:MapPoint;
private var multigraphPointSymbol:SimpleMarkerSymbol; //shows clicked point on map

private var multigraphXCoord:mx.controls.TextInput; //text input value
private var multigraphYCoord:mx.controls.TextInput; //text input value
private var multigraphYCoordVal:String; //value passed to multigraph - make available to sharing map function
private var multigraphXCoordVal:String; //value passed to multigraph - make available to sharing map function
		
private function addPhenographTool(toolObject:ObjectProxy):void {
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
	helpTextArea.height = 70;
	c.addChild(helpTextArea);
	
	//Add x and y input fields
	var multigraphYCoordLabel:mx.controls.Label = new mx.controls.Label;
	multigraphYCoordLabel.text = "Latitude: ";
	multigraphYCoordLabel.y = 85;
	multigraphYCoordLabel.x = 2;
	c.addChild(multigraphYCoordLabel);
	
	multigraphYCoord = new mx.controls.TextInput;
	multigraphYCoord.y=75;
	multigraphYCoord.x=80;
	multigraphYCoord.text = "";
	multigraphYCoord.width = 70;
	c.addChild(multigraphYCoord);
	
	var multigraphXCoordLabel:mx.controls.Label = new mx.controls.Label;
	multigraphXCoordLabel.text = "Longitude: ";
	multigraphXCoordLabel.y = 105;
	multigraphXCoordLabel.x = 2;
	c.addChild(multigraphXCoordLabel);
	
	multigraphXCoord = new mx.controls.TextInput;
	multigraphXCoord.y=105;
	multigraphXCoord.x=80;
	multigraphXCoord.text = "";
	multigraphXCoord.width = 70;
	c.addChild(multigraphXCoord);
	
	//add graph button
	var graphButton:Button = new Button;
	graphButton.label = "Make Graph"
	graphButton.y=135;
	graphButton.x=2;
	graphButton.addEventListener(MouseEvent.CLICK, graphButton_ClickHandler);
	c.addChild(graphButton);

	//add canvas to accordion
	toolsAccordion.addChild(c);
	
	//set up symbol
	multigraphPointSymbol = new SimpleMarkerSymbol("circle",15,0xFFFF00,0.5);
		
	//add graphics layers needed for any tasks
	multigraphGraphicsLayer = new GraphicsLayer;
	multigraphGraphicsLayer.spatialReference = new SpatialReference(102100);
	theMap.addLayer(multigraphGraphicsLayer);
}

private function multigraphFaultFunction(error:Object):void {
	cursorManager.removeBusyCursor();
	Alert.show(String(error), "Projection Error");
}

private function phenographClickHandler(evt:MapMouseEvent):void {
	cursorManager.setBusyCursor();
	
	//save point 
	multigraphPoint = theMap.toMapFromStage(evt.stageX, evt.stageY);
	
	//add graphic to map
	clearMultigraphGraphicLayers();
	var graphic:Graphic = new Graphic(multigraphPoint, multigraphPointSymbol);                
	multigraphGraphicsLayer.add(graphic);
	
	//project to lat long to show in label
	const latlong:MapPoint = WebMercatorUtil.webMercatorToGeographic(multigraphPoint) as MapPoint;
     
	var windowLabel:String = "MODIS NDVI for Lat: " + latlong.y.toFixed(6) + " Lon: " + latlong.x.toFixed(6);
	multigraphXCoord.text = latlong.x.toFixed(6);
	multigraphYCoord.text = latlong.y.toFixed(6);
	
	//show Multigraph
	multigraphXCoordVal = String(multigraphPoint.x);
	multigraphYCoordVal = String(multigraphPoint.y);
	var urlString:String = "http://rain.nemac.org/timeseries/tsmugl_product.cgi?args=CONUS_NDVI,"+multigraphXCoordVal+","+multigraphYCoordVal;
	var mGraph:ClosableTitleWindow = Multigraph.createPopUp(urlString,685,385,windowLabel,theMap,null,false); 
	
	cursorManager.removeBusyCursor();
	
	//update share URL if open
	//updateShareURL();
}

private function phenographOpenFromSharedURL(urlString:String):void {
	//runs when multigraph is defined in URL - only one graph is handled
	
	var xValue:String = urlString.split(",")[0];
	var yValue:String = urlString.split(",")[1];

	phenographOpenFromLatLong(xValue, yValue);
}

private function graphButton_ClickHandler(evt:MouseEvent):void {
	//runs when user clicks button to Make Graph
	
	var xValue:String = multigraphXCoord.text;
	var yValue:String = multigraphYCoord.text;

	phenographOpenFromLatLong(xValue, yValue);
}

private function phenographOpenFromLatLong(xValue:String, yValue:String):void {
	//must convert point to WebMercator and show on map
	//then must call Phenograph
	
	//first check point to see if valid
	var pointGood:Boolean = true;
	
	if (isNaN(Number(xValue)) || (xValue == "")) {
		Alert.show("Please enter a valid number for the Longitude.");
		multigraphXCoord.setFocus();
		pointGood = false;
	}
	if (isNaN(Number(yValue)) || (yValue == "")) {
		Alert.show("Please enter a valid number for the Latitude.");
		multigraphYCoord.setFocus();
		pointGood = false;
	}
	
	var longVal:Number = Number(xValue);
	var latVal:Number = Number(yValue);
	
	if ((longVal < -180) || (longVal > 180)) {
		Alert.show("Please enter a Longitude between -180 and +180.");
		multigraphXCoord.setFocus();
		pointGood = false;
	}
	if ((latVal < -90) || (latVal > 90)) {
		Alert.show("Please enter a Latitude between -90 and +90.");
		multigraphYCoord.setFocus();
		pointGood = false;
	}
	
	//convert point to Web Mercator
	if (pointGood) {
		multigraphPoint = new MapPoint(Number(longVal), Number(latVal), new SpatialReference(4326));
		
		//project to web mercator to show point on map
		const webmerc:MapPoint = WebMercatorUtil.geographicToWebMercator(multigraphPoint) as MapPoint;
		multigraphYCoordVal = String(webmerc.y);
		multigraphXCoordVal = String(webmerc.x);
		
		//add graphic to map
		clearMultigraphGraphicLayers();
		multigraphPoint = new MapPoint(Number(multigraphXCoordVal), Number(multigraphYCoordVal), new SpatialReference(102100));
		var graphic:Graphic = new Graphic(multigraphPoint, multigraphPointSymbol);                
		multigraphGraphicsLayer.add(graphic);
		
		//show Multigraph window
		var windowLabel:String = "MODIS NDVI for Lat: " + multigraphYCoord.text + " Lon: " + multigraphXCoord.text;
		var urlString:String = "http://rain.nemac.org/timeseries/tsmugl_product.cgi?args=CONUS_NDVI,"+multigraphXCoordVal+","+multigraphYCoordVal;
		var mGraph:ClosableTitleWindow = Multigraph.createPopUp(urlString,685,385,windowLabel,theMap,null,false);   
		cursorManager.removeBusyCursor();
		
		//update share URL if open
		//updateShareURL();
	}
}

public function clearMultigraphGraphicLayers():void {
	multigraphGraphicsLayer.clear();   
}
