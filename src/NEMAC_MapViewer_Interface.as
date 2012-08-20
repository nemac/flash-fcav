// ActionScript file

// when mouse (cursor) is on the map ...
private function mapLoadHandler():void {
    theMap.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseMoveHandler);
}

// ... show coordinates of current (mouse) location
private function mapMouseMoveHandler(event:MouseEvent):void {
    const mapPoint:MapPoint = theMap.toMapFromStage(event.stageX, event.stageY);
    const latlong:MapPoint = WebMercatorUtil.webMercatorToGeographic(mapPoint) as MapPoint;
    coordsLabel.text = "Lat/Long is: " + latlong.y.toFixed(6) + " / " + latlong.x.toFixed(6);
}

private function resizeTOCs(evt:ResizeEvent): void {
	var theAccordionTOC:Accordion = Accordion(evt.target);
	for (var i:uint=0; i< (theTOCCanvasArray.length); i++) {
		theTOCCanvasArray[i].width = theAccordionTOC.width *0.95;
		theTOCCanvasArray[i].height = theAccordionTOC.height *0.95;
	}
}

private function getLayerInfoObjectByMapId(mapId:String):ObjectProxy {
	for (var i:uint=0; i< (theMapLayers.length); i++) {
    	if (theMapLayers[i].mapId == mapId) {
    		var theLayerInfoObject:ObjectProxy =  theMapLayers[i];
    		break;
    	}
    }
	return theLayerInfoObject;
}

//needed to reset the map extent when state goes to Thumbnail
private function resizeMapHandler(event:ResizeEvent):void {
	if (theMap.loaded) {
		theMap.removeEventListener(ResizeEvent.RESIZE, resizeMapHandler);
		theMap.addEventListener(ExtentEvent.EXTENT_CHANGE, map_extentChangeHandler);
	}
	
}

private function updateShareURL():void {
	//if user has share map tool open, update the URL
  	if (toolsAccordion.selectedChild.name == "ShareMap") {
  		setShareURL();
	}	
}
//needed to reset the map extent when state goes to Thumbnail
private function map_extentChangeHandler(evt:ExtentEvent):void {
    theMap.removeEventListener(ExtentEvent.EXTENT_CHANGE, map_extentChangeHandler);
    
    callLater(
        function():void
        {
             if (areaAC.selectedItem == null) {
					theMap.extent = theOriginalMapExtent.expand(1.1);
				}
				else {
					setMapExtent(areaAC.selectedItem.areaID);
				}
             //theMap.centerAt(origMapCenter);
        }//,
        //[ origMapCenter ]
    );
    theMap.addEventListener(ResizeEvent.RESIZE, resizeMapHandler);
}

private function mapClickHandler(event:MapMouseEvent):void { 
	
	//branch to correct tool code
	if (currentMapTool == "Spatial Query") {
		//spatialQueryClickHandler(event);
	}
	else if (currentMapTool == "Phenograph") {
		phenographClickHandler(event);
	}
	else if (currentMapTool == "Identify") {
		identifyClickHandler(event);
	}
}

private function toolBoxToggleButtonBarClickHandler(event:ItemClickEvent):void {
	switch (event.index) {
		case 0: //pan
			currentMapTool = "Pan";
			navToolbar.activate(NavigationTool.PAN);
			CursorManager.removeAllCursors();
			break;

		case 1: //zoom in
			currentMapTool = "ZoomIn";
			navToolbar.activate(NavigationTool.ZOOM_IN);
			break;

		case 2: //zoom out
			currentMapTool = "ZoomOut";
			navToolbar.activate(NavigationTool.ZOOM_OUT);
			break;

		case 3: //identify
			currentMapTool = "Identify";
			navToolbar.deactivate();
			crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
			break;

		case 4: //phenograph
			currentMapTool = "Phenograph";
			navToolbar.deactivate();
			crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
			break;

		default:
			CursorManager.removeAllCursors();	
	}
}

private function toolBoxButtonBarClickHandler(event:ItemClickEvent):void {
	switch (event.index) {
		case 0: //previous extent
			navToolbar.zoomToPrevExtent();
			break;

		case 1: //next extent
			navToolbar.zoomToNextExtent();
			break;

		case 2: //full extent
			//navToolbar.zoomToFullExtent();
			theMap.extent = theOriginalMapExtent.expand(1.1);
			break;	

		default:	
	}
}

private function hideClickedLegendItem(evt:MouseEvent):void {
	
	//find legend item for clicked item and get service
	var clickedImageServiceName:String;
	for (var i:uint=0; i<theLegendArray.length; i++) {
		if (theLegendArray[i].mapId == evt.currentTarget.name) { //image objects only have names - storing mapID there
			clickedImageServiceName = theLegendArray[i].serviceName;
			break;
		}
	}
	
	//get needed TOC and call its function to hide clicked layer
	var thisTOCCanvas:Canvas = Canvas(layerAccordion.getChildByName(clickedImageServiceName + "_Canvas"));
	var thisTOC:LayerTOC = LayerTOC(thisTOCCanvas.getChildByName(clickedImageServiceName + "_LayerTOC"));
	thisTOC.hideClickedLayer(evt.currentTarget.name);
}

protected function drawButtonBar_itemClickHandler(event:ItemClickEvent):void {
	if (drawButtonBar.selectedIndex < 0)
    {
        // when toggling a tool off, deactivate it
        drawToolbar.deactivate();
    }
    else
    {
        switch (event.index)
        {
            case 0: //"MAPPOINT"
            {
                drawToolbar.activate(DrawTool.MULTIPOINT);
                break;
            }
            /* case "MULTIPOINT":
               myDrawTool.activate(DrawTool.MULTIPOINT);
             break; */
            /* case "Single Line":
               myDrawTool.activate(DrawTool.LINE);
             break; */
            case 1: //"POLYLINE"
            {
                drawToolbar.activate(DrawTool.POLYLINE);
                break;
            }
            case 2: //"FREEHAND_POLYLINE"
            {
                drawToolbar.activate(DrawTool.FREEHAND_POLYLINE);
                break;
            }
            case 3: //"POLYGON"
            {
                drawToolbar.activate(DrawTool.POLYGON);
                break;
            }
            case 4: //"FREEHAND_POLYGON"
            {
                drawToolbar.activate(DrawTool.FREEHAND_POLYGON);
                break;
            }
            case 5: //"EXTENT"
            {
                drawToolbar.activate(DrawTool.EXTENT);
                break;
            }
            case 6: //"CIRCLE"
            {
                drawToolbar.activate(DrawTool.CIRCLE);
                break;
            }
            case 7: //"ELLIPSE"
            {
                drawToolbar.activate(DrawTool.ELLIPSE);
                break;
            }
            case 8: //"CLEAR"
            {
                drawingGraphicsLayer.clear();
                drawToolbar.deactivate();
                drawButtonBar.selectedIndex = -1;
                break;
            }
            /*case 9: //"REDO"
            {
            	if ((drawingGraphicsLayer.numChildren > 0) && didUndo) {
                	drawingGraphicsLayer.add(lastRemovedDrawingGraphic);
             	}
                break;
            }
            case 10: //"UNDO"
            {
            	if (drawingGraphicsLayer.numChildren > 0) {
            		//lastRemovedDrawingGraphic = drawingGraphicsLayer.getChildAt(drawingGraphicsLayer.numChildren-1);
               	 	drawingGraphicsLayer.removeChildAt(0);
               	 	//didUndo = true;
             	}
             	drawToolbar.deactivate();
                break;
            }*/    
        }
    }
}

protected function drawTool_drawEndHandler(event:DrawEvent):void {
    // reset after finished drawing a feature
    drawToolbar.deactivate();
    drawButtonBar.selectedIndex = -1;
}

private function toggleToolsPanel():void {
	toolsPanel.visible = !(toolsPanel.visible);	
}

private function toggleLayersPanel():void {
	layersPanel.visible = !(layersPanel.visible);	
}

private function toggleDrawingPanel():void {
	drawingPanel.visible = !(drawingPanel.visible);	
}

private function toggleTimeSliderPanel():void {
	timeSliderPanel.visible = !(timeSliderPanel.visible);
	//show selected layer
	timeSliderSetup(timeSliderPanel.visible);	
}

private function toggleAboutPanel():void {
	if (currentState=='About') {
		currentState = "";
	}
	else {
		currentState='About';
	}
}

private function openLink(evt:ItemClickEvent): void {
	var url:String = evt.item.url;
	var myURL:URLRequest = new URLRequest(url); 
	navigateToURL(myURL, "_blank");   
}

private function reallyHideESRILogo(map:Map):void {
	/*for (var i:int=0;i<map.numChildren;i++) {
		var component:UIComponent = map.getChildAt(i) as UIComponent;
		if (component.className == "StaticLayer") {
			 for (var j:int=0;j<component.numChildren;j++) {
				var stComponent:UIComponent = component.getChildAt(j) as UIComponent;
				if (stComponent.className == "Image") {
					var img:Image = stComponent as Image;
					if (img.source.toString().indexOf("logo") > 0) {
						stComponent.visible = false;
						return;
					}
				}
			}
		}
	}*/
}

private function anXMLLoadError(evt:Event):void {
	//do nothing, just let map set to default ESRI extents
}


private function getMetadata(name:String):String {
	//loop over metadata array to get needed info
	
	if (theMetadataArray.length == 0) {
		return "";
	}
	else {
		for (var i:uint; i<theMetadataArray.length; i++) {
			if (theMetadataArray[i].name == name) {
				return theMetadataArray[i].value;
			}
		}
	}
	
	return "";
}


private function getCurrentDate():String {
	
	//get date info from system
	var mydate_ist:Date = new Date();
	var month_ist:String = String(mydate_ist.getMonth()+1);
	var day_ist:String = String(mydate_ist.getDate());
	var year_ist:String = String(mydate_ist.getFullYear());
	
	//put zeros where needed
	if (Number(month_ist)<10) {
	     month_ist = "0" + month_ist;
	} 
	if (Number(day_ist)<10) {
	     day_ist = "0" + day_ist;
	} 

	return month_ist + "-" + day_ist + "-" + year_ist;
}

private function getCurrentTime():String {
	
	//get date info from system
	var mydate_ist:Date = new Date();
	var hrs_ist:String = String(mydate_ist.getHours());
	var mins_ist:String = String(mydate_ist.getMinutes());
	var sec_ist:String = String(mydate_ist.getSeconds());
	
	//put zeros where needed
	if (Number(hrs_ist)<10) {
	     hrs_ist = "0" + hrs_ist;
	} 
	if (Number(mins_ist)<10) {
	     mins_ist = "0" + mins_ist;
	} 
	if (Number(sec_ist)<10) {
	     sec_ist = "0" + sec_ist;
	} 

	return hrs_ist+":"+mins_ist+":"+sec_ist;
}
