// ActionScript file

[Bindable] 
private var queryTask:QueryTask = new QueryTask;
private var queryGraphicsLayer:GraphicsLayer; //layer for showing query results         
private var queryText:TextInput;
private var theDataGrid:DataGrid;
private var queryFieldsArray:Array;
private var queryLayerID:uint;
private var queryLayerMapId:String;
private var c:Canvas;

private function addFindTool(toolObject:ObjectProxy):void {
	//save settings for tool
	queryFieldsArray = toolObject.querySearchFieldNames.split(",");
	
	//make canvas for tool
	c = new Canvas;
	c.label = toolObject.toolLabel; 
	c.width = toolsAccordion.width;
	c.height = toolsAccordion.height;
	c.name = toolObject.toolName;
	c.id = toolObject.toolName + "Canvas";
	c.addEventListener(ResizeEvent.RESIZE, resizeGrid);
	
	//add label to canvas
	var llabel:Label = new Label;
	llabel.text = toolObject.helpText;
	llabel.y=5;
	llabel.x=2;
	c.addChild(llabel);
	
	//add text input to canvas
	queryText = new TextInput;
	queryText.y=25;
	queryText.x=2;
	queryText.width = 100;
	c.addChild(queryText);
	
	//add query button
	var queryButton:Button = new Button;
	queryButton.label = "Find"
	queryButton.y=25;
	queryButton.x=110;
	queryButton.addEventListener(MouseEvent.CLICK, doFind);
	c.addChild(queryButton);
	
	//add clear button
	var clearButton:Button = new Button;
	clearButton.label = "Clear"
	clearButton.y=25;
	clearButton.x=175;
	clearButton.addEventListener(MouseEvent.CLICK, doClearFind);
	c.addChild(clearButton);
	
	//add data grid to canvas
	theDataGrid = new DataGrid;
	theDataGrid.id = "theGrid";
	theDataGrid.y=50;
	theDataGrid.x=2;
	theDataGrid.percentWidth = 95;
	theDataGrid.addEventListener(MouseEvent.CLICK, zoomToResult);
 	c.addChild(theDataGrid);
	
	//add canvas to accordion
	toolsAccordion.addChild(c);
	
	//define query Task
	queryLayerMapId = getLayerMapId(toolObject.queryLayer, toolObject.queryLayerService);
	queryLayerID = getLayerId(toolObject.queryLayer, toolObject.queryLayerService);
	queryTask.url = theMapServerPath + "rest/services/" + toolObject.queryLayerServiceFolder + "/" + toolObject.queryLayerService + "/MapServer/" + queryLayerID;				
	
	//add graphics layers needed for any tasks
	queryGraphicsLayer = new GraphicsLayer;
	queryGraphicsLayer.id = "queryGraphicsLayer";
	theMap.addLayer(queryGraphicsLayer);
}

private function getLayerMapId(layerName:String, serviceName:String):String {
	for (var i:uint=0; i< (theMapLayers.length); i++) {
    	if ((theMapLayers[i].name == layerName) && (theMapLayers[i].serviceName == serviceName)) {
    		var mapId:String =  theMapLayers[i].mapId;
    		break;
    	}
    }
	return mapId;
}

private function getLayerId(layerName:String, serviceName:String):uint {
	for (var i:uint=0; i< (theMapLayers.length); i++) {
    	if ((theMapLayers[i].name == layerName) && (theMapLayers[i].serviceName == serviceName)) {
    		var layerId:uint =  theMapLayers[i].id;
    		break;
    	}
    }
	return layerId;
}
            
private function resizeGrid(evt:ResizeEvent):void {
	c.width = toolsAccordion.width;
	theDataGrid.width = toolsAccordion.width*0.95;
}

private function doClearFind(evt:Event):void {
	queryGraphicsLayer.clear();
	theDataGrid.dataProvider = null;               
}

private function doFind(evt:Event):void {
	queryGraphicsLayer.clear();                
 	//cursorManager.setBusyCursor(); 
 	
	//build query string
	var querySQLText:String = "";
	for (var i:uint=0;i<queryFieldsArray.length;i++) {
		if (i > 0) {
			querySQLText = querySQLText + " or ";
		}
		querySQLText = querySQLText + queryFieldsArray[i] + " like '%" + queryText.text + "%'";
	}
	//define query 
	var query:Query = new Query;
	query.returnGeometry = true;
 	query.outSpatialReference = theMap.spatialReference;
 	query.outFields = queryFieldsArray;
 	query.where = querySQLText;
 	
 	//run query task
	queryTask.showBusyCursor;
	queryTask.execute(query, new AsyncResponder(queryResultFunction, onFault));
}

private function onFault(info:Object, token:Object = null):void {
	Alert.show(info.toString());
}

private function queryResultFunction(featureSet:FeatureSet, token:Object = null):void {
	var queryGraphic:Graphic;                
 	
 	//resultSummary.text = "Found " + event.queryResults.length + " results.";                
 	var resultCount:int = featureSet.features.length;                
 	for (var i:Number = 0; i < resultCount; i++) {                    
 		queryGraphic = featureSet.features[i];                    
 		//queryGraphic.toolTip =  event.queryResults[i].foundFieldName + ": " + event.queryResults[i].value;                    
 		switch (queryGraphic.geometry.type) {                        
 			case Geometry.MAPPOINT:                            
 				queryGraphic.symbol = toolPointSymbolFind;                            
 				break;                        
 			case Geometry.POLYLINE:                            
 				queryGraphic.symbol = toolPolylineSymbolFind;                           
 				break;                        
 			case Geometry.POLYGON:                            
 				queryGraphic.symbol = toolPolygonSymbolFind;                            
 				break;                   
 		}                   
 		queryGraphicsLayer.add(queryGraphic);  
 		/*
 		//if this layer is not on, turn it on
		var theLayer:ArcGISDynamicMapServiceLayer = ArcGISDynamicMapServiceLayer(theMap.getLayer(queryLayerMapId));
        if (theLayer.visible == false) {
        	LayerTOC.showLayer(queryLayerID, queryLayerMapId);        	
        } 
        */    
 	}
 	
 	// zoom to extent of all features   
 	if (resultCount > 0) {                 
	 	var unionedExtent:Extent = new Extent(); 
	 	                   
	 	unionedExtent = getFeatureExtent(featureSet.features[0].geometry);                    
	 	for (var j:Number = 1; j < resultCount; j++) {
	 		unionedExtent = unionedExtent.union(getFeatureExtent(featureSet.features[j].geometry));
		}    
		if (unionedExtent != null) { 	            
			theMap.extent = unionedExtent.expand(1.1); // zoom out a little 
		}	
 	}
  	theDataGrid.dataProvider = queryTask.executeLastResult.attributes;
  	var theColArray:Array = [];
  	for (i=0;i<queryFieldsArray.length;i++) {
		var theColumn:DataGridColumn = new DataGridColumn;
		theColumn.dataField = queryFieldsArray[i];
		theColumn.headerText = queryFieldsArray[i].replace("_", " ");
		theColArray.push(theColumn);
	}
	theDataGrid.columns = theColArray;
 	cursorManager.removeBusyCursor();
}

private function getFeatureExtent(geom:Geometry):Extent {
	var theExtent:Extent;
	var factor:Number = 0.1;

	switch (geom.type) {                        
 		case Geometry.MAPPOINT: 
 			theExtent = new Extent(MapPoint(geom).x - factor, MapPoint(geom).y - factor, MapPoint(geom).x + factor, MapPoint(geom).y + factor, MapPoint(geom).spatialReference);               
 			break;                        
 		case Geometry.POLYLINE:                            
 			theExtent = Polyline(geom).extent;                         
 			break;                        
 		case Geometry.POLYGON:                            
 			theExtent = Polygon(geom).extent;                           
 			break;  
	}
	return theExtent;
}

private function zoomToResult(evt:MouseEvent):void {
	var i:uint;
	
	//zoom to selected feature
	var selFeature:Graphic = queryTask.executeLastResult.features[theDataGrid.selectedIndex];
	if (selFeature == null) return;
	
	switch (selFeature.geometry.type) {                        
 		case Geometry.MAPPOINT:                            
 			theMap.centerAt(MapPoint(selFeature.geometry));                          
 			break;                        
 		case Geometry.POLYLINE:                            
 			theMap.extent = Polyline(selFeature.geometry).extent.expand(1.1);                         
 			break;                        
 		case Geometry.POLYGON:                            
 			theMap.extent = Polygon(selFeature.geometry).extent.expand(1.1);                           
 			break;  
	}
	
	//now set the feature to outline symbol - first turn off any existing outlines
	var theQueryGraphic:Graphic = new Graphic;
	for (i=0; i<queryGraphicsLayer.numChildren; i++) {
		theQueryGraphic = Graphic(queryGraphicsLayer.getChildAt(i));
		switch (theQueryGraphic.geometry.type) {                        
	 		case Geometry.MAPPOINT:                            
	 			theQueryGraphic.symbol = toolPointSymbolFind;                         
	 			break;                        
	 		case Geometry.POLYLINE:                            
	 			theQueryGraphic.symbol = toolPolylineSymbolFind;                        
	 			break;                        
	 		case Geometry.POLYGON:                            
	 			theQueryGraphic.symbol = toolPolygonSymbolFind;                           
	 			break;  
		}
	}
	
	switch (theQueryGraphic.geometry.type) {                        
 		case Geometry.MAPPOINT:                            
 			selFeature.symbol = toolPointSymbolFindSelect;                         
 			break;                        
 		case Geometry.POLYLINE:                            
 			selFeature.symbol = toolPolylineSymbolFindSelect;                        
 			break;                        
 		case Geometry.POLYGON:                            
 			selFeature.symbol = toolPolygonSymbolFindSelect;                           
 			break;  
	} 
}

private function findLayerByName(strName:String):int {
	var returnValue:uint = 0;
	
	for (var i:int=(layerInfos.length-1); i>=0; i--) {
		if (layerInfos[i].name == strName) {
			returnValue = layerInfos[i].id;
			break;
		}	
	}
	return returnValue;
}
