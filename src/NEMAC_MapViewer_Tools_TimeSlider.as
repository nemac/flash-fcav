// ActionScript file
import com.esri.ags.events.TimeExtentEvent;
import com.esri.ags.layers.ArcGISImageServiceLayer;
import com.esri.ags.tasks.supportClasses.Query;

import mx.utils.ObjectProxy;

private var timeSliderLayer:ArcGISImageServiceLayer;
private var timeSliderDates:String;
private var timeSliderCurrentStop:uint = 0;
private var timeSliderQueryTask:QueryTask = new QueryTask;

private var timeDateArrayCollection:ArrayCollection; //stores ALL dates for current time layer selected
//(as opposed to array holding dates within user selected start and end dates, which may be different)
private var timeDateArrayStartIndex:int = -1; //index of user selected start date for time slider
private var timeDateArrayEndIndex:int = -1; //index of user selected end date for time slider

private var timeDateArrayStartSelectionIndex:uint; //save combo box selection in case user picks bad date range
private var timeDateArrayEndSelectionIndex:uint; //save combo box selection in case user picks bad date range

private function addTimeSliderTool(toolObject:ObjectProxy):void {
	//set help text
	//timeSliderLabel.text = toolObject.helpText;
	
	//fill combo box of time layers
	cbxTimeSlider.dataProvider = toolObject.toolServiceArray;
	cbxTimeSlider.labelField = "label";
	
	//define query task
	timeSliderQueryTask.concurrency = "last";
	timeSliderQueryTask.useAMF = false;
}

private function timeSliderSetup(timeSliderPanelVisible:Boolean):void {
	
	//if showing panel, add selected item in combo box
	if (timeSliderPanelVisible) {
		cursorManager.setBusyCursor(); 
		if (cbxTimeSlider.selectedItem.type == "raster") {
			//add the image service
			addTimeSliderImageService(cbxTimeSlider.selectedItem.url)
		}
	}
	
	//else hide item in combo box
	else {
		theMap.removeLayer(timeSliderLayer);		
	}
	
}

private function cbxTimeSlider_change():void {
	//clear current layer
	if (timeSliderLayer != null) {
		theMap.removeLayer(timeSliderLayer);
	}
	
	//add layer from drop down
	cursorManager.setBusyCursor();
	timeDateArrayStartIndex = -1;
	timeDateArrayEndIndex = -1;
	
	if (cbxTimeSlider.selectedItem.type == "raster") {
		
		//add the image service
		addTimeSliderImageService(cbxTimeSlider.selectedItem.url);
	}
}

private function refreshTimeSlider():void {
	//clear current layer
	if (timeSliderLayer != null) {
		theMap.removeLayer(timeSliderLayer);
	}
	
	//add layer from drop down
	cursorManager.setBusyCursor();
	
	if (cbxTimeSlider.selectedItem.type == "raster") {
		
		//add the image service
		addTimeSliderImageService(cbxTimeSlider.selectedItem.url);
	}
}

private function addTimeSliderImageService(serviceUrl:String):void {
	//cursorManager.setBusyCursor();
	
	timeSliderLayer = new ArcGISImageServiceLayer;
	timeSliderLayer.id = "timeSliderLayer"; //only one layer ever visible at a time - use constant value here
	timeSliderLayer.useMapTime = true;
	timeSliderLayer.url = serviceUrl;
	timeSliderLayer.addEventListener(LayerEvent.LOAD, loadTimeSliderImageService);	
}

private function loadTimeSliderImageService(evt:com.esri.ags.events.LayerEvent):void {
	//add loaded image service to map
	theMap.addLayer(timeSliderLayer, theMapLayers.length-6);//below jurisdictions and roads

	//add layer info to layer array
	var infoArray:ObjectProxy = new ObjectProxy;
	infoArray.id = "timeSliderLayer"; //only one layer ever visible at a time - use constant value here
	infoArray.mapId = "timeSliderLayer";
	infoArray.name = cbxTimeSlider.selectedItem.label;
	infoArray.visible = true;
	infoArray.transparency = 0;
	infoArray.identifyFlag = true;
	infoArray.settingsWindowOpen = false;
	
	theMapLayers.addItemAt(infoArray,0); //entire map
	
	//load time slider stops
	getTimeSliderDateStops();
}

private function getTimeSliderDateStops():void {
	
	//query for all date times in layer
	timeSliderQueryTask.url = cbxTimeSlider.selectedItem.url + "/query";
	
	var query:Query = new Query;
	query.returnGeometry = false;
	query.outFields = new Array("Date_Time");
 	query.where = "OBJECTID>=0"; //get all layers/dates
	timeSliderQueryTask.execute(query, new AsyncResponder(loadTimeSliderDateArray, timeSliderQueryFaultFunction));

}

private function loadTimeSliderDateArray(featureSet:FeatureSet, token:Object = null):void {
	var resultCount:int = featureSet.features.length;                
 	var dateValue:Date;
 	var dateObject:ObjectProxy;
 	
 	timeDateArrayCollection = new ArrayCollection();
 	//this function builds the array collection of all dates for the current time layer
 	
 	//grab all date values from query results
	for (var i:Number = 0; i < resultCount; i++) {                    
 		var dateTimeValue:String = featureSet.features[i].attributes.Date_Time;
 		dateValue = new Date;
 		dateValue.time = Number(dateTimeValue);
 		dateObject = new ObjectProxy;
 		dateObject.time = dateValue;
 		dateObject.label = timeSliderDateFormatter.format(dateValue.toUTCString());
 		timeDateArrayCollection.addItem(dateObject);
 	}
 	
	//update start and end date drop down lists
	//timeSliderStartDateMenu.dataProvider = timeDateArrayCollection;
	//timeSliderEndDateMenu.dataProvider = timeDateArrayCollection;
	
	//now set time slider stops to use this array
	if (timeDateArrayStartIndex == -1) {
		timeDateArrayStartIndex = 0;
	}
	timeDateArrayStartSelectionIndex = timeDateArrayStartIndex;
	//timeSliderStartDateMenu.selectedIndex = timeDateArrayStartSelectionIndex;
	
	if (timeDateArrayEndIndex == -1 ) {
		timeDateArrayEndIndex = timeDateArrayCollection.length - 1;
	}
	timeDateArrayEndSelectionIndex = timeDateArrayEndIndex;
	//timeSliderEndDateMenu.selectedIndex = timeDateArrayEndSelectionIndex;
	
	loadTimeSliderDateStops(timeDateArrayStartIndex, timeDateArrayEndIndex);
}

private function loadTimeSliderDateStops(timeDateArrayStartIndex:uint, timeDateArrayEndIndex:uint):void {
	//this function sets the slider date range to match the user selected start and end dates
	//user selection comes from drop downs which show ALL dates for selected time layer
	var timeSliderDateArray:Array = new Array;
	
	for (var i:Number = timeDateArrayStartIndex; i <= timeDateArrayEndIndex; i++) {                    
 		timeSliderDateArray.push(timeDateArrayCollection[i].time);
	}
	
	timeSlider.timeStops = timeSliderDateArray;
 	timeSlider.thumbIndexes = new Array(0);
 	
 	//update label to show new date
 	timeSliderLabel.text = timeSliderDateFormatter.format(timeSliderDateArray[0].toUTCString());
 	
 	//update legend
 	timeSliderLegendImage.source = cbxTimeSlider.selectedItem.legendUrl;
	cursorManager.removeBusyCursor();
	
	//load first image in time layers
	timeSlider.next();
	timeSlider.previous();
	
}

private function setTimeSliderStartDate(evt:ListEvent):void {
	timeDateArrayStartIndex = evt.target.selectedIndex;
		
	if (timeDateArrayStartIndex >= timeDateArrayEndIndex) {
		Alert.show("Invalid date selection!");
		timeDateArrayStartIndex = timeDateArrayStartSelectionIndex;
		//timeSliderStartDateMenu.selectedIndex = timeDateArrayStartSelectionIndex;
	}
	else {
		timeDateArrayStartSelectionIndex = timeDateArrayStartIndex;
		loadTimeSliderDateStops(timeDateArrayStartIndex, timeDateArrayEndIndex);
	}
}

private function setTimeSliderEndDate(evt:ListEvent):void {
	timeDateArrayEndIndex = evt.target.selectedIndex;
		
	if (timeDateArrayEndIndex <= timeDateArrayStartIndex) {
		Alert.show("Invalid date selection!");
		timeDateArrayEndIndex = timeDateArrayEndSelectionIndex;
		//timeSliderEndDateMenu.selectedIndex = timeDateArrayEndSelectionIndex;
	}
	else {
		timeDateArrayEndSelectionIndex = timeDateArrayEndIndex;
		loadTimeSliderDateStops(timeDateArrayStartIndex, timeDateArrayEndIndex);
	}
}

private function timeSliderQueryFaultFunction(error:Object, clickGraphic:Graphic = null):void {
	Alert.show(String(error), "Time Slider Error");
}

private function openTimeSliderLayerSettings(evt:MouseEvent, mapID:String):void {	
	evt.currentTarget.selected = false;
	var thisLayerInfo:ObjectProxy = getLayerInfoObjectByMapId(mapID);
	if (thisLayerInfo.settingsWindowOpen == false) {
		//open properties dialog
		var propDialog:LayerPropertiesDialog = LayerPropertiesDialog(PopUpManager.createPopUp(this, LayerPropertiesDialog, false)); 
		propDialog.layerMapID = mapID;
		propDialog.showLayerProperties();
	}
}
