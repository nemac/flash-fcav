
         import com.esri.ags.Graphic;
         
         import flash.xml.XMLNode;
         
         import mx.utils.ObjectProxy;
                  
[Bindable]  
 private var identifyFeatureGraphicsLayer:GraphicsLayer; //layer highlighting user clicked objects
 private var clickGraphicsLayer:GraphicsLayer; //layer for identify popup window          
 private var lastIdentifyResultGraphic:Graphic = new Graphic;
 private var clickedPoint:MapPoint;
 private var clickGraphic:Graphic;
 private var identifyTask:IdentifyTask = new IdentifyTask;
 private var identifyImageServiceTask:ImageServiceIdentifyTask = new ImageServiceIdentifyTask;
 private var identifyResultsTabs:TabNavigator;
 private var identifyLinkFields:String = ""; //string storing identify fields that go to a URL

 private var theIdentifyServiceCounter:int; //variable for looping over current services
 private var foundSomeResult:Boolean;  //indicates if we found any result from any service
 private var identifyWMSLayers:Array = new Array; //stores WMS layers to identify

private function addIdentifyTool():void {
	//add graphics layers needed for any tasks
	identifyFeatureGraphicsLayer = new GraphicsLayer;
	identifyFeatureGraphicsLayer.id="identifyFeatureGraphicsLayer";
	theMap.addLayer(identifyFeatureGraphicsLayer);
	
	clickGraphicsLayer = new GraphicsLayer;
	clickGraphicsLayer.id = "clickGraphicsLayer";
	theMap.addLayer(clickGraphicsLayer);
}

private function identifyClickHandler(event:MapMouseEvent):void {          
 	cursorManager.setBusyCursor();               
 	
 	//clear previous results
 	clearGraphicLayers();
 	theIdentifyResultsArray =  new ArrayCollection;
 	foundSomeResult=false;
 	
 	//save point
 	clickedPoint = event.mapPoint; 

	//show identify window
	identifySuperPanel.visible=true;

 	//start with first service and perform identify
 	theIdentifyServiceCounter = 0;
    identifyOneService();
}

private function identifyOneService():void {
	//set up click graphic
	clickGraphic = new Graphic(clickedPoint, clickPtSym);                
 	clickGraphicsLayer.add(clickGraphic); 

 	//define Identify Task
	identifyTask.concurrency = "last";
	var theCurrentIdentifyServiceName:String = theServiceNameArray[theIdentifyServiceCounter].name;
	var theCurrentIdentifyServiceFolder:String = theServiceNameArray[theIdentifyServiceCounter].folder;
	identifyTask.url = theMapServerPath + "rest/services/" + theCurrentIdentifyServiceFolder + "/" + theCurrentIdentifyServiceName + "/MapServer";	
	
 	//set identify parameters
 	var identifyParams:IdentifyParameters = new IdentifyParameters();                
 	identifyParams.returnGeometry = true;                
 	identifyParams.tolerance = 5;                
 	identifyParams.width = theMap.width;                
 	identifyParams.height = theMap.height;                
 	identifyParams.geometry = clickedPoint;                
 	identifyParams.mapExtent = theMap.extent;                
 	identifyParams.spatialReference = theMap.spatialReference;   
 	
 	//build array of just visible layers (in legend array) if they are part of this current service
 	//also check to see if they are set as identifyFlag = true
 	var layerIdArray:Array = new Array;
 	for (var i:uint=0;i<theMapLayers.length;i++) {
 		if (theMapLayers[i].visible == true) {
	 		if (theMapLayers[i].mapId.substr(0, theCurrentIdentifyServiceName.length) == theCurrentIdentifyServiceName) {
	 			if (getLayerInfoObjectByMapId(theMapLayers[i].mapId).identifyFlag) {
	 				layerIdArray.push(theMapLayers[i].id); 
		 		}		
	 		}
	 	}
 	}
 	
 	//if we have any visible and identifiable layers in this service, run identify task
 	if (layerIdArray.length > 0) {
 		identifyParams.layerIds = layerIdArray;    
 		identifyParams.layerOption = "all";  
 	    cursorManager.setBusyCursor();  
 		identifyTask.execute(identifyParams, new AsyncResponder(identifyResultFunction, identifyFaultFunction, clickGraphic));  
 	}	
 	else { //go to next service
		theIdentifyServiceCounter++;
		if (theIdentifyServiceCounter < theServiceNameArray.length) {
			identifyOneService();
		}
		else {
			identifyWMSServices(); //start on any WMS services
		}
 	}          
}

private function identifyResultFunction(results:Array, clickGraphic:Graphic = null):void {
	
	if (results && results.length > 0) {
		cursorManager.setBusyCursor(); 
		//loop over each result
		var foundGeometry:Boolean = false;
		var thisResultObject:ObjectProxy;
		
		for (var j:uint=0;j<results.length;j++) {
			var result:IdentifyResult = results[j];
			
			//if we have geometry (non-WMS) then we add graphic to map
			if (result.feature.geometry) {
				foundGeometry = true;
				var resultGraphic:Graphic = result.feature;
				
				switch (resultGraphic.geometry.type) {
					case Geometry.MAPPOINT: {
						resultGraphic.symbol = toolPointSymbol;
						break;                        
					}                        
					case Geometry.POLYLINE: {
						resultGraphic.symbol = toolPolylineSymbol;
						break;
					}
					case Geometry.POLYGON: {
						resultGraphic.symbol = toolPolygonSymbol;
						break;
					}                    
				}
				lastIdentifyResultGraphic = resultGraphic;
				identifyFeatureGraphicsLayer.add(lastIdentifyResultGraphic);
				
				//now we build attribute string and add to text area
				var text:TextArea = new TextArea();
				text.editable = false;
				text.percentHeight = 100;
				text.percentWidth = 100;
				var theIdentifyText:String = "";
				
				//dump results to an array to sort by display name
				var tmp:Array=new Array();
				for (var str:String in result.feature.attributes) {
					if(str.toLowerCase().indexOf("shape")==-1 && str.toLowerCase().indexOf("objectid")==-1 && str.toLowerCase().indexOf("globalid")==-1){	
						tmp.push({displayName:str,value:result.feature.attributes[str]});
					}
				}
				tmp.sortOn("displayName");			
				
				//loop over array to build display string
				var strDisplayName:String;
				for (var i:uint=0; i<tmp.length; i++) {
					if (tmp[i].displayName == null) {
						strDisplayName = "VALUE"
					}
					else {
						strDisplayName = tmp[i].displayName;
					}
					var parentName:String = theServiceNameArray[theIdentifyServiceCounter].name;
					if (((parentName == "EWS_EFETAC-NASA") || (parentName == "EWS_RSAC-FHTET")) && (tmp[i].displayName == "Pixel Value")) { //bad hard coding here
						tmp[i].value = String(tmp[i].value) + " (" + String(((Number(tmp[i].value)*200/255)-100).toFixed(2)) + "%)";
					}
					if (identifyLinkFields.indexOf(tmp[i].displayName) > -1) {
						theIdentifyText =  theIdentifyText + "<b>" + strDisplayName + ":</b> <a href='" + tmp[i].value.replace("&", "&amp;").replace("<", "&lt;").replace("<", "&gt;") + "' target='_blank'>" + tmp[i].value.replace("&", "&amp;").replace("<", "&lt;").replace("<", "&gt;") + "</a>\n"; 
					}
					else {
						theIdentifyText =  theIdentifyText + "<b>" + strDisplayName + ":</b> " + tmp[i].value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;") + "\n"; 
					}
				}
				
				//add result to array
				thisResultObject = new ObjectProxy;
				var resultIdentifier:String
				if ((result.displayFieldName == "null") || (result.displayFieldName == "")) {
					resultIdentifier = "" 
				}
				else {
					resultIdentifier = ": " + result.feature.attributes[result.displayFieldName].substring(0, 99);
				}
				thisResultObject.name = result.layerName + resultIdentifier;
				thisResultObject.text = theIdentifyText;
				theIdentifyResultsArray.addItem(thisResultObject);
				
				//save we found something in this service to control whether to show the No Results message
				foundSomeResult=true;
			}
		}//over all records
	}//if we found records
	
	//go to next service
	theIdentifyServiceCounter++;
	if (theIdentifyServiceCounter < theServiceNameArray.length) {
		identifyOneService(); //go to next ESRI service
	}
	else {
		identifyWMSServices(); //start on any WMS services
	}
}

private function identifyWMSServices():void {
	identifyWMSLayers = new Array;
	
	//loop over all layers and find visible and identifiable WMS layers
	for (var i:int=0; i<theMapLayers.length; i++) {
		var theWMSLayer:ObjectProxy = theMapLayers[i];
		if ((theWMSLayer.type == "WMS") && (theWMSLayer.visible == true) && (theWMSLayer.identifyFlag == true)) {
			identifyWMSLayers.push(theWMSLayer);
		}	
	}
	
	if (identifyWMSLayers.length > 0) {
		//start with first service and perform identify
 		theIdentifyServiceCounter = 0;
 		identifyOneWMSLayer();
	}
	else {
		identifyTimeSeriesLayer(); //do any time series layer
	}

}

private function identifyOneWMSLayer():void {
	var currentWMSLayer:ObjectProxy = identifyWMSLayers[theIdentifyServiceCounter];
	var getFeatureInfoURL:String = currentWMSLayer.url;
	var loader:URLLoader;
	
	//see if WMS layer is from NEMAC EWS site
	if (false /*getFeatureInfoURL.indexOf("fswms.nemac.org") >= 0*/) {   	//use custom Python script
/*		
		//point to new URL
		getFeatureInfoURL = "http://fswms.nemac.org/ewsidentify?";//lon=-108.78&lat=39.69&layer=EFETAC-NASA_current"
	
		//add layers
		getFeatureInfoURL = getFeatureInfoURL + "layer="+currentWMSLayer.layer;
		
		//add dimensions and coordinates
		const latlong:MapPoint = WebMercatorUtil.webMercatorToGeographic(clickedPoint) as MapPoint;
		getFeatureInfoURL = getFeatureInfoURL + "&lon="+latlong.x+"&lat="+latlong.y;
		
		//send request to URL
		loader = new URLLoader(new URLRequest(getFeatureInfoURL));
		loader.addEventListener(Event.COMPLETE, identifyNEMACWMSResultFunction);
		loader.addEventListener(IOErrorEvent.IO_ERROR, anXMLLoadError);
*/
 	}
 	else {  	// use standard WMS GetFeatureInfo request
		//add needed tags to URL
		getFeatureInfoURL = getFeatureInfoURL + "&SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&STYLES=&FORMAT=image/png&INFO_FORMAT=application/vnd.ogc.gml";
		
		//add bounding box and CRS
		getFeatureInfoURL = getFeatureInfoURL + "&BBOX="+theMap.extent.xmin+","+theMap.extent.ymin+","+theMap.extent.xmax+","+theMap.extent.ymax+"&CRS="+currentWMSLayer.srs;
		
		//add layers
		getFeatureInfoURL = getFeatureInfoURL + "&LAYERS="+currentWMSLayer.layer+"&QUERY_LAYERS="+currentWMSLayer.layer;
		
		//add dimensions and coordinates
		var screenPoint:Point = theMap.toScreen(clickedPoint);
		getFeatureInfoURL = getFeatureInfoURL + "&WIDTH="+theMap.width+"&HEIGHT="+theMap.height+"&X="+screenPoint.x+"&Y="+screenPoint.y;
		
		//send request to URL
		loader = new URLLoader(new URLRequest(getFeatureInfoURL));
		loader.addEventListener(Event.COMPLETE, identifyWMSResultFunction);
		loader.addEventListener(IOErrorEvent.IO_ERROR, anXMLLoadError); 		
 	}
}

private function identifyNEMACWMSResultFunction(evt:Event):void {
	//get XMl object from result
	var _xml:XML = XML(evt.target.data);
	var xDoc:XMLDocument = new XMLDocument();
    xDoc.ignoreWhite = true;
	xDoc.parseXML(_xml.toXMLString());

	//parse XML to find value node
	var theMainNode:XMLNode = xDoc.firstChild;
	var theResult:String = "";
	
	if (theMainNode.childNodes.length > 0) {
		//python script returns XML file of <value>##</value>
		var theResultNode:XMLNode = theMainNode.firstChild; 
		theResult = theResultNode.nodeValue;

		//add result to array
		var thisResultObject:ObjectProxy = new ObjectProxy;
		thisResultObject.name = identifyWMSLayers[theIdentifyServiceCounter].name;
		
		var parentName:String = identifyWMSLayers[theIdentifyServiceCounter].serviceName;
		if (parentName == "MODIS_Change_Detection_Products") { //bad hard coding here
			thisResultObject.text = "VALUE: " + theResult + " (" + String(((Number(theResult)*200/255)-100).toFixed(2)) + "%)";
		}
		else {
			thisResultObject.text = "VALUE: " + theResult;
		}
			
		theIdentifyResultsArray.addItem(thisResultObject);
		foundSomeResult = true;
	}
			
	//go to next service
	theIdentifyServiceCounter++;
	if (theIdentifyServiceCounter < identifyWMSLayers.length) {
		identifyOneWMSLayer(); //start on any WMS services
	}
	else {
		identifyTimeSeriesLayer(); //do any time series layer
	}
}

private function findDescendentNodeValue(node:XMLNode, name:String):String {
	for (var i:uint=0; i<node.childNodes.length; ++i) {
		if (node.childNodes[i].localName == name) {
			return node.childNodes[i].firstChild.nodeValue;
		} else {
			var value:String = findDescendentNodeValue(node.childNodes[i], name);
			if (value != null) { return value; }
		} 
	}
	return null;
}

private function findDescendentNodeMatchingRegExp(node:XMLNode, regexp:RegExp):XMLNode {
	for (var i:uint=0; i<node.childNodes.length; ++i) {
		if (regexp.exec(node.childNodes[i].localName) != null) {
			return node.childNodes[i];
		} else {
			var child:XMLNode = findDescendentNodeMatchingRegExp(node.childNodes[i], regexp);
			if (child != null) { return child; }
		}
	}
	return null;
}

private function getNodeValueAsString(node:XMLNode):String {
	if (node.firstChild == null) { return null; }
	return node.firstChild.nodeValue;
}

private function identifyWMSResultFunction(evt:Event):void {
	//get XMl object from result
	try {
		var _xml:XML = XML(evt.target.data);
		var xDoc:XMLDocument = new XMLDocument();
		xDoc.ignoreWhite = true;
		xDoc.parseXML(_xml.toXMLString());
		
		//parse XML to find value node
		var theMainNode:XMLNode = xDoc.firstChild;
		var theResult:String = "";
		
		if (theMainNode.childNodes.length > 0) {
			/*
			var theResultNode:XMLNode = theMainNode.firstChild.firstChild; //msGMLOutput/<layername>_layer/<layername>_feature
			for (var i:uint=0;i<theResultNode.childNodes.length;i++) {
			if (theResultNode.childNodes[i].localName == "value_0") {
			theResult = theResultNode.childNodes[i].firstChild.nodeValue;
			break;
			}
			}
			*/
			var results : Array = [];
			var featureNode:XMLNode = findDescendentNodeMatchingRegExp(theMainNode, /^.*_feature$/);
			for (var i:uint=0;i<featureNode.childNodes.length;i++) {
				try {
					if (featureNode.childNodes[i].nodeName != "gml:boundedBy") {
						var name:String = featureNode.childNodes[i].nodeName;
						var value:String = getNodeValueAsString(featureNode.childNodes[i]);
						if (name == "value_0") {
							name = "RASTER PIXEL VALUE";
							value = value + ' (' + (Number(getNodeValueAsString(featureNode.childNodes[i]))*200.0/255.0-100).toFixed(2) + '%)'
						}
						results.push({ 'name'  : name,
							'value' : value });
					}
				} catch (ex) {
				}
			}
			
			//theResult = findDescendentNodeValue(theMainNode, 'value_0');
			
			//add result to array
			var thisResultObject:ObjectProxy = new ObjectProxy;
			thisResultObject.name = identifyWMSLayers[theIdentifyServiceCounter].name;
			
			var parentName:String = identifyWMSLayers[theIdentifyServiceCounter].serviceName;
			
			thisResultObject.text = "";
			for (var i:uint=0; i<results.length; ++i) {
				if (i > 0) {
					thisResultObject.text = thisResultObject.text + "\n";
				}
				thisResultObject.text = thisResultObject.text + results[i].name + ": " + results[i].value;
			}
			
			/*
			if (parentName == "MODIS_Change_Detection_Products") { //bad hard coding here
			thisResultObject.text = "VALUE: " + theResult + " (" + String(((Number(theResult)*200/255)-100).toFixed(2)) + "%)";
			}
			else {
			thisResultObject.text = "VALUE: " + theResult;
			}
			*/
			
			theIdentifyResultsArray.addItem(thisResultObject);
			foundSomeResult = true;
			
		}
		
		//go to next service
		theIdentifyServiceCounter++;
		if (theIdentifyServiceCounter < identifyWMSLayers.length) {
			identifyOneWMSLayer(); //start on any WMS services
		}
		else {
			identifyTimeSeriesLayer(); //do any time series layer
		}
	} catch (ex2) {
	}	
}

private function identifyTimeSeriesLayer():void {
	//if time series is on, and layer is set to identify, identify it
	if ((/*toggleTimeSlider.selected == false*/true) && (getLayerInfoObjectByMapId("timeSliderLayer").identifyFlag)) {
		identifyImageServiceTask.concurrency = "last";
		identifyImageServiceTask.url = cbxTimeSlider.selectedItem.url;
		
		var identifyParams:ImageServiceIdentifyParameters = new ImageServiceIdentifyParameters();
		identifyParams.geometry = clickedPoint;
		cursorManager.setBusyCursor(); 
 	    
 	    identifyImageServiceTask.execute(identifyParams, new AsyncResponder(identifyTimeSeriesResultFunction, identifyFaultFunction, clickGraphic));  
	}
	else {
		//finally, finish the identify
		finishIdentify();
	}
}

private function identifyTimeSeriesResultFunction(results:ImageServiceIdentifyResult, clickGraphic:Graphic = null):void {
	//loop over results and show date and value for all times
	var thisResultObject:ObjectProxy;
	
	if (results && results.catalogItems.features.length > 0) {
		foundSomeResult = true;
		
		thisResultObject = new ObjectProxy;
		thisResultObject.name = cbxTimeSlider.selectedItem.label;
		var identifyString:String = "";
		var theDate:Date;
		var theValue:String;
		
		for (var i:uint=0;i<results.catalogItems.features.length;i++) {
			theDate = new Date();
			theDate.time = Number(results.catalogItems.attributes[i].Date_Time);
			theValue = results.properties.Values[i];
			
			if ((thisResultObject.name.indexOf("MODIS") >= 0) || (thisResultObject.name.indexOf("Archived NRT") >= 0)) { //bad hard coding here
				identifyString = identifyString + "<b>" + timeSliderDateFormatter.format(theDate.toUTCString()) 
					+ ":</b> " + theValue + " (" + String(((Number(theValue)*200/255)-100).toFixed(2)) + "%)"  + "\n";
			}
			else {
				identifyString = identifyString + "<b>" + timeSliderDateFormatter.format(theDate.toUTCString()) 
					+ ":</b> " + theValue  + "\n";
			}
		}
		
		thisResultObject.text = identifyString;
		theIdentifyResultsArray.addItem(thisResultObject);
	}
	//finally, finish the identify
	finishIdentify();
}


private function finishIdentify():void {
	//update identify window
	if (foundSomeResult) {
		cbxIdentifySuperPanel.visible = true;
		txtIdentifySuperPanel.htmlText = cbxIdentifySuperPanel.selectedItem.text;
	}
	else {
		cbxIdentifySuperPanel.visible = false;
		txtIdentifySuperPanel.text = "No results found."
	}
	cursorManager.removeBusyCursor();
}

private function identifyFaultFunction(error:Object, clickGraphic:Graphic = null):void {
	Alert.show(String(error), "Identify Error");
}


private function layerIsInLegendArray(layerId:uint):Boolean {
	var returnValue:Boolean = false;
	for (var i:uint=0;i<theLegendArray.length;i++) {
		if (theLegendArray[i].id == layerId) {
			returnValue = true;
			break;
		}
	}
	return returnValue;
}

public function clearGraphicLayers():void {
	identifyFeatureGraphicsLayer.clear();
	clickGraphicsLayer.clear();   
}
 
 
