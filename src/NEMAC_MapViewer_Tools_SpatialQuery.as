// ActionScript file
      
 [Bindable]  
 private var spatialQueryFeatureGraphicsLayer:GraphicsLayer; //layer highlighting user clicked objects
 private var spatialQueryPoint:MapPoint;
 private var spatialQueryIdentifyTask:IdentifyTask = new IdentifyTask;
 private var spatialQueryDataGrid:DataGrid;
 private var spatialQueryFieldsArray:Array;
 private var spatialQueryBufferLayerID:uint;
 private var spatialQueryFindLayerID:uint;
 private var spatialQueryFindLayerMapId:String;
 private var spatialQueryGeometryService:GeometryService = new GeometryService;
 private var spatialQueryFindTask:QueryTask = new QueryTask;
 private var spatialQuerySpatialReference:SpatialReference;
 
private function addSpatialQueryTool(toolObject:ObjectProxy):void {
	//save settings for tool
	spatialQueryBufferLayerID = getSQLayerId(toolObject.bufferLayerName, toolObject.bufferLayerService);
	spatialQueryFindLayerID = getSQLayerId(toolObject.searchLayerName, toolObject.searchLayerService);
	spatialQueryFindLayerMapId = getSQLayerMapId(toolObject.searchLayerName, toolObject.searchLayerService);
	
	spatialQueryFieldsArray = toolObject.querySearchFieldNames.split(",");
	spatialQuerySpatialReference = ArcGISDynamicMapServiceLayer(theMap.getLayer(spatialQueryFindLayerMapId)).spatialReference;
        
	//make canvas for tool
	var c:Canvas = new Canvas;
	c.label = toolObject.toolLabel; 
	c.width = toolsAccordion.width;
	c.height = toolsAccordion.height;
	c.name = toolObject.toolName;
	c.id = toolObject.toolName + "Canvas";
	c.addEventListener(ResizeEvent.RESIZE, resizeSpatialQueryGrid);
	
	//add label to canvas
	var llabel:TextArea = new TextArea;
	llabel.text=toolObject.helpText;
	llabel.y=5;
	llabel.x=2;
	llabel.height=35;
	llabel.percentWidth=95;
	llabel.wordWrap=true;
	llabel.editable=false;
	c.addChild(llabel);
	
	//add text input to canvas
	queryText = new TextInput;
	queryText.text = "100";
	queryText.y=45;
	queryText.x=2;
	queryText.width = 50;
	c.addChild(queryText);
	
	//add data grid to canvas
	spatialQueryDataGrid = new DataGrid;
	spatialQueryDataGrid.id = "theGrid";
	spatialQueryDataGrid.y=70;
	spatialQueryDataGrid.x=2;
	spatialQueryDataGrid.percentWidth = 95;
	spatialQueryDataGrid.addEventListener(MouseEvent.CLICK, zoomToSpatialQueryResult);
 	c.addChild(spatialQueryDataGrid);
 	
 	//add canvas to accordion
	toolsAccordion.addChild(c);
	
	//define SpatialQuery Task - this is the identify task to find the clicked feature
	spatialQueryIdentifyTask.concurrency = "last";
	spatialQueryIdentifyTask.url = theMapServerPath + "rest/services/" + toolObject.bufferLayerServiceFolder + "/" + toolObject.bufferLayerService + "/MapServer";
	
	
	spatialQueryFindTask.concurrency = "last";
	spatialQueryFindTask.url = theMapServerPath + "rest/services/" + toolObject.searchLayerServiceFolder + "/" + toolObject.searchLayerService + "/MapServer/" + spatialQueryFindLayerID;			
	
	//define geometry service used
	spatialQueryGeometryService.url = "http://sampleserver2.arcgisonline.com/ArcGIS/rest/services/Geometry/GeometryServer"
	
	//add graphics layers needed for any tasks
	spatialQueryFeatureGraphicsLayer = new GraphicsLayer;
	spatialQueryFeatureGraphicsLayer.id="spatialQueryFeatureGraphicsLayer";
	theMap.addLayer(spatialQueryFeatureGraphicsLayer);
	
	clickGraphicsLayer = new GraphicsLayer;
	clickGraphicsLayer.id = "clickGraphicsLayer";
	theMap.addLayer(clickGraphicsLayer);
    
}

private function getSQLayerMapId(layerName:String, serviceName:String):String {
	for (var i:uint=0; i< (theMapLayers.length); i++) {
    	if ((theMapLayers[i].name == layerName) && (theMapLayers[i].serviceName == serviceName)) {
    		var mapId:String =  theMapLayers[i].mapId;
    		break;
    	}
    }
	return mapId;
}

private function getSQLayerId(layerName:String, serviceName:String):uint {
	for (var i:uint=0; i< (theMapLayers.length); i++) {
    	if ((theMapLayers[i].name == layerName) && (theMapLayers[i].serviceName == serviceName)) {
    		var layerId:uint =  theMapLayers[i].id;
    		break;
    	}
    }
	return layerId;
}
  
private function resizeSpatialQueryGrid(evt:ResizeEvent):void {
	if (c != null) {
		c.width = toolsAccordion.width;
		spatialQueryDataGrid.width = toolsAccordion.width*0.95;
	}
}

private function spatialQueryClickHandler(event:MapMouseEvent):void { 
	if (isNaN(parseInt(queryText.text))) {
		return;
	}
	         
 	cursorManager.setBusyCursor();               
 	clearSpatialQueryGraphicLayers();
                
 	var clickGraphic:Graphic = new Graphic(event.mapPoint, clickPtSym);                
 	clickGraphicsLayer.add(clickGraphic); 
 	clickedPoint = event.mapPoint; 

 	//set spatialQuery parameters
 	var spatialQueryParams:IdentifyParameters = new IdentifyParameters();                
 	spatialQueryParams.returnGeometry = true;                
 	spatialQueryParams.tolerance = 5;                
 	spatialQueryParams.width = theMap.width;                
 	spatialQueryParams.height = theMap.height;                
 	spatialQueryParams.geometry = event.mapPoint;                
 	spatialQueryParams.mapExtent = theMap.extent;                
 	spatialQueryParams.spatialReference = theMap.spatialReference;   
 	
 	//build array of just the layer defined in task
 	spatialQueryParams.layerIds = [spatialQueryBufferLayerID];    
 	spatialQueryParams.layerOption = "all";  
 	    
 	spatialQueryIdentifyTask.execute(spatialQueryParams, new AsyncResponder(spatialQueryIdentifyResultFunction, spatialQueryFaultFunction, clickGraphic));  	          
}

private function spatialQueryIdentifyResultFunction(results:Array, clickGraphic:Graphic = null):void {
	cursorManager.setBusyCursor();               
 	var featureArray:Array = [];
		
	if (results && results.length > 0) {
		//get all results
		for (var j:uint=0;j<1;j++) {
			//if we have geometry (non-WMS) then add feature to array for buffering
			if (results[j].feature.geometry) {
					featureArray.push(results[j].feature);
					var graphic:Graphic = results[j].feature;
					graphic.symbol = toolPolygonSymbol;
					spatialQueryFeatureGraphicsLayer.add(graphic);
				}
		}//over all records
	}//if we found records	
	
	if (featureArray.length > 0) {
		var bufferParameters:BufferParameters = new BufferParameters();
		
		bufferParameters.geometries = featureArray;
		//77.8 feet per second at 40 N latitude
		//bufferParameters.distances = [parseFloat(queryText.text)/77.8/3600];
		//bufferParameters.distances = [parseFloat(queryText.text)/0.3048]; //convert feet to meters
		bufferParameters.distances = [parseFloat(queryText.text)]; //convert feet to meters
		bufferParameters.unit = GeometryService.UNIT_FOOT;
		bufferParameters.bufferSpatialReference = theMap.spatialReference;
		bufferParameters.unionResults = true;
		spatialQueryGeometryService.addEventListener(GeometryServiceEvent.BUFFER_COMPLETE, spatialQueryBufferCompleteHandler);
		spatialQueryGeometryService.buffer(bufferParameters);
	}
	cursorManager.removeBusyCursor();
}

private function spatialQueryBufferCompleteHandler(event:GeometryServiceEvent):void {
	spatialQueryGeometryService.removeEventListener(GeometryServiceEvent.BUFFER_COMPLETE, spatialQueryBufferCompleteHandler);

	//loop over each buffer result and find parcels that intersect
	for each (var geometry:Polygon in event.result) {
		
		//add buffer polygon to map
		var graphic:Graphic = new Graphic();
        graphic.geometry = geometry;
		graphic.symbol = toolPolygonSymbol;
		spatialQueryFeatureGraphicsLayer.add(graphic);

		//now search for parcels that are within buffer	
		var query:Query = new Query;
		query.returnGeometry = true;
	 	query.outSpatialReference = theMap.spatialReference;
	 	query.outFields = spatialQueryFieldsArray;
	 	query.geometry = graphic.geometry;
	 	//query.spatialRelationship = SPATIAL_REL_INTERSECTS
	 	//query.where = querySQLText;
	 	
	 	//run query task
		spatialQueryFindTask.showBusyCursor;
		spatialQueryFindTask.execute(query, new AsyncResponder(spatialQueryFindResultFunction, spatialQueryFaultFunction));

	}
	cursorManager.removeBusyCursor();
}

private function spatialQueryFindResultFunction(featureSet:FeatureSet, token:Object = null):void {
	var queryGraphic:Graphic;                
 	spatialQueryFeatureGraphicsLayer.clear();
 	
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
 		spatialQueryFeatureGraphicsLayer.add(queryGraphic);  
 		
 		//if this layer is not on, turn it on
		//var theLayer:ArcGISDynamicMapServiceLayer = ArcGISDynamicMapServiceLayer(theMap.getLayer(spatialQueryFindLayerMapId));
        //if (theLayer.visible == false) {
        	//LayerTOC.showLayer(spatialQueryFindLayerID, spatialQueryFindLayerMapId);        	
        //}     
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
 	
 	//show results in data grid
  	spatialQueryDataGrid.dataProvider = spatialQueryFindTask.executeLastResult.attributes;
  	var theColArray:Array = [];
  	for (i=0;i<spatialQueryFieldsArray.length;i++) {
		var theColumn:DataGridColumn = new DataGridColumn;
		theColumn.dataField = spatialQueryFieldsArray[i];
		theColumn.headerText = spatialQueryFieldsArray[i];
		theColArray.push(theColumn);
	}
	spatialQueryDataGrid.columns = theColArray;
}

private function spatialQueryFaultFunction(error:Object, clickGraphic:Graphic = null):void {
	Alert.show(String(error), "SpatialQuery Error");
}

public function clearSpatialQueryGraphicLayers():void {
	spatialQueryFeatureGraphicsLayer.clear();
	clickGraphicsLayer.clear();   
}

private function zoomToSpatialQueryResult(evt:MouseEvent):void {
	var i:uint;
	
	//zoom to selected feature
	var selFeature:Graphic = spatialQueryFindTask.executeLastResult.features[spatialQueryDataGrid.selectedIndex];
	if (selFeature == null) { 
		return;
	}
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
	for (i=0; i<spatialQueryFeatureGraphicsLayer.numChildren; i++) {
		theQueryGraphic = Graphic(spatialQueryFeatureGraphicsLayer.getChildAt(i));
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
 
 
  
   
 
 
