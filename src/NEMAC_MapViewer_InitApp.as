import mx.core.INavigatorContent;
import mx.utils.ObjectProxy;

private var thePortalDatabase:String //stores portal database if needed
private var theWMSGroupArray:Array = []; //array for any WMS layers
private var layerInfos:Array; //info array for layers in service
private var crosshairCursorID:int;
private var thisServiceName:String //current service name when adding layers
private var thisServiceFolder:String //current service folder when adding layers
private var theServiceCounter:int; //variable for looping over current services

private var thisWMSLayerName:String //current WMS name when looping over WMS layers to set their titles
private var theWMSGroupCount:int=0; //total count of WMS groups of layers

private var theLayers:ArcGISDynamicMapServiceLayer; // variable for current service layers
private var theLayerCounter:int=0; //tracks position of layer in total layer list
private var theCurrentMapLayers:ArrayCollection = new ArrayCollection; // variable for current map layer information
private var theTOCCanvasArray:Array = new Array; //list of TOC objects to resize when accordion resizes
private var theOriginalMapExtent:Extent;

private var applicationUrlPrefix:String;
private var htmlPageURL:String;

//** add the following section for the ShareMap function **//
// Declare bindable properties in Application scope - these are the URL query string values.
private var sharedTheme:String = "";
private var sharedBasemap:String = "";
private var sharedExtent:String = "";
private var sharedAlphas:String = ""; //layer transparencies
//private var sharedMultigraph:String = "";
private var sharedPrint:String = "";
private var sharedPrintTitle:String = "";
private var selectedLayerAccordionGroupName:String = ""; // name of accordion group marked selected="true" in config file (WITHOUT "_Canvas" suffix)
private var sharedLayerAccordionGroupName:String = "";   // name of accordian group mentioned in share URL, if any (WITH "_Canvas" suffix)

private var sharedLayers:String = "";

private var sharedLayerMap:Array = []; // HashMap to keep track of names of shared layers: [ LID : true ] for each shared layer LID

private function layerIsShared(lid:String):Boolean {
    // returns true if and only iff the layer with the given lid is a shared layer
    return sharedLayerMap[lid];
}

private var actionsToBeDoneOnceUponStartupAfterMapLoadingDone:Boolean = false;

//function that runs when app is loaded - to read config file and load layers
private function initApp():void {
    // Set this.applicationUrlPrefix to the URL of the directory where our SWF
    // file came from (url of SWF file is "this.url"):
    var i:int = this.url.lastIndexOf("/");
    if (i>=0) {
        this.applicationUrlPrefix = this.url.substring(0, i);
    } else {
        this.applicationUrlPrefix = "";
    }

    //Save map dimensions for later
    originalAppHeight = this.height;
    originalAppWidth = this.width;

    //get any passed HTML query values, if this is a shared map
    var qs:QueryString = new QueryString;
    this.htmlPageURL = qs.url.replace(/#.*$/, '').replace(/\?.*$/, '').replace(/\&.*$/, '');
    if (qs.parameters.theme) {
        sharedTheme = qs.parameters.theme;
    }
    if (qs.parameters.basemap) {
        sharedBasemap = qs.parameters.basemap;
    }
    if (qs.parameters.extent) {
        sharedExtent = qs.parameters.extent;
    }
    if (qs.parameters.layers) {
        sharedLayers = qs.parameters.layers;
        for each (var lid:String in sharedLayers.split(",")) {
            if (lid) {
                sharedLayerMap[lid] = true;
            }
        }
    }
    if (qs.parameters.accgp) {
        sharedLayerAccordionGroupName = qs.parameters.accgp;
    }
    if (qs.parameters.alphas) {
        sharedAlphas = qs.parameters.alphas;
    }
    if (qs.parameters.state) {
        if ((qs.parameters.state == "Print") && (qs.parameters.print)) {
            currentState = "Printing";
            sharedPrint = qs.parameters.print;
            sharedPrintTitle = qs.parameters.title;
        }
    }
    /*if (qs.parameters.multigraph) {
      sharedMultigraph = qs.parameters.multigraph;
      }*/

    /*sharedLayers="US_Jurisdictions_Layer2,US_Jurisdictions_Layer3,WMS_Layer1,";
      sharedTheme="CONUS_Vegetation_Monitoring_Tools";
      sharedExtent="-10149810.719986908,3826393.7110688975,-10003204.499736138,3893276.1108183367";
      sharedBasemap="Streets";
      sharedAlphas="1,0,0.25,";*/

    //read in XML file and set map config settings
    //this also loads map zooms, views, tools, and any WMS layers
    //when it ends, it loads the main ArcGIS server layers
    //cursorManager.setBusyCursor();
    var theConfigFile:String = FlexGlobals.topLevelApplication.parameters.configFile;
    var loader:URLLoader = new URLLoader(new URLRequest(this.applicationUrlPrefix + "/config/" + theConfigFile + "_config.xml"));
    loader.addEventListener(Event.COMPLETE, configXMLLoaded);
    loader.addEventListener(IOErrorEvent.IO_ERROR, anXMLLoadError);
}

private function configXMLLoaded(evt:Event):void {
    evt.target.removeEventListener(Event.COMPLETE, configXMLLoaded);

    var mapViewsNodePresent:Boolean=false;
    var mapZoomsNodePresent:Boolean=false;
    var reportsNodePresent:Boolean=false;
    var linksNodePresent:Boolean=false;

    //load xml and set to XML document
    var _xml:XML = XML(evt.target.data);
    var xDoc:XMLDocument = new XMLDocument();
    xDoc.ignoreWhite = true;
    xDoc.parseXML(_xml.toXMLString());

    //get extent node
    var theConfigNodes:Array = xDoc.firstChild.childNodes;
    var viewArray:Array;
    var viewObject:ObjectProxy;
    var i:int;
    var j:int;
    var m:int;
    var n:int;

    for (var k:int=0;k<theConfigNodes.length;k++) {

        var theNode:XMLNode = theConfigNodes[k];

        switch (theNode.localName) {

        case "application":
            dp0.title = theNode.attributes.title;
            break;

        case "server":
            theMapServerPath = theNode.attributes.map_path;
            //theLegendServerPath = theNode.attributes.legend_path;
            break;

        case "services":
            for (i=0; i<theNode.childNodes.length; i++) {
                theServiceNameArray.addItem({name: theNode.childNodes[i].attributes.name,
                                             folder: theNode.childNodes[i].attributes.folder,
                                             label: theNode.childNodes[i].attributes.label});
            }
            break;

        case "extent":
            /**
             *  There are two types of extents that need to be stored
             *          1) The start map extent
             *          2) The zoom to full extent (the globe button)
             *  There are two different cases that are handled
             *          1) If there is no shared extent, the full extent is
             *             used as the start map extent
             *          2) If there is a shared extent, shared map extent is
             *             used as the start map extent, but the full extent
             *             is still preserved as the full extent
             **/

            // Bounds for the zoom to full extent
            var xmin:Number;
            var ymin:Number;
            var xmax:Number;
            var ymax:Number;
            var wkid:int;

            // No shared extent, so use the full extent as the start
            if (sharedExtent == "") {
                xmin = theNode.attributes.xmin;
                ymin = theNode.attributes.ymin;
                xmax = theNode.attributes.xmax;
                ymax = theNode.attributes.ymax;
                wkid = theNode.attributes.wkid;
                theOriginalMapExtent = new Extent(xmin,ymin,xmax,ymax,new SpatialReference(wkid));
                theMap.extent = theOriginalMapExtent.expand(1.1);
            }
            // Shared extent, so use the shared as the start, but preserve the full
            else {
                // Set the zoom to max extent
                xmin = theNode.attributes.xmin;
                ymin = theNode.attributes.ymin;
                xmax = theNode.attributes.xmax;
                ymax = theNode.attributes.ymax;
                wkid = theNode.attributes.wkid;
                theOriginalMapExtent = new Extent(xmin,ymin,xmax,ymax,new SpatialReference(wkid));

                // Set the start extent
                var sharedXMin:Number = sharedExtent.split(",")[0];
                var sharedYMin:Number = sharedExtent.split(",")[1];
                var sharedXMax:Number = sharedExtent.split(",")[2];
                var sharedYMax:Number = sharedExtent.split(",")[3];
                var sharedWkid:int = theNode.attributes.wkid;
                var sharedMapExtent:Extent = new Extent(sharedXMin,sharedYMin,sharedXMax,sharedYMax,new SpatialReference(sharedWkid));
                theMap.extent = sharedMapExtent;
            }
            break;

        case "images":
            //get map background images and save to array for combo box
            for (i=0; i<theNode.childNodes.length; i++) {
                theMapImageArray.addItem({name: theNode.childNodes[i].attributes.name, label: theNode.childNodes[i].attributes.label, url: theNode.childNodes[i].attributes.url});
            }

            //if we have a shared basemap, set that, else show first basemap
            var imageLayer:ArcGISTiledMapServiceLayer = ArcGISTiledMapServiceLayer(theMap.getLayer("tiledESRILayer"));
            if (sharedBasemap == "") {
                imageLayer.url = theNode.childNodes[0].attributes.url;
                backgroundImageMenu.selectedIndex = 0;
            }
            else {
                var foundBasemap:Boolean = false;
                for (i=0; i<theMapImageArray.length; i++) {
                    if (theMapImageArray[i].name == sharedBasemap) {
                        imageLayer.url = theMapImageArray[i].url;
                        backgroundImageMenu.selectedIndex = i;
                        foundBasemap = true;
                        break;
                    }
                }
                if (!foundBasemap) {
                    imageLayer.url = theNode.childNodes[0].attributes.url;      //in case basemap no longer a choice
                    backgroundImageMenu.selectedIndex = 0;
                }
            }
            break;

        case "legend":
            //get legend node and save legend type
            legendType = theNode.attributes.type;
            theLegendServerPath = theNode.attributes.legendServerPath;

            //see if any legend groups and fill array
            var groupName:String;

            for (i=0; i<theNode.childNodes.length; i++) {
                groupName = theNode.childNodes[i].attributes.name;
                if (theNode.childNodes[i].localName == "legendGroup") {
                    theLegendGroupArray.addItem(groupName);
                }
                else if (theNode.childNodes[i].localName == "layerGroup") {
                    theLayerGroupArray.addItem(groupName);
                }
            }
            break;

        case "mapviews":
            //get mapviews node and save info if any defined
            for (i=0; i<theNode.childNodes.length; i++) {
                viewArray = new Array;
                viewObject = new ObjectProxy;

                var theGroupNodes:Array = theNode.childNodes[i].childNodes;
                for (j=0; j<theGroupNodes.length; j++) {
                    viewArray[j] = theGroupNodes[j].attributes.name;
                }

                viewObject.label = theNode.childNodes[i].attributes.label;
                viewObject.name = theNode.childNodes[i].attributes.name;
                viewObject.zoom = theNode.childNodes[i].attributes.zoom;
                viewObject.xmin = theNode.childNodes[i].attributes.xmin;
                viewObject.xmax = theNode.childNodes[i].attributes.xmax;
                viewObject.ymin = theNode.childNodes[i].attributes.ymin;
                viewObject.ymax = theNode.childNodes[i].attributes.ymax;
                viewObject.wkid = theNode.childNodes[i].attributes.wkid;
                viewObject.layerGroups = viewArray;
                theMapViewArray.addItem(viewObject);
            }

            //if we have a shared theme (view), set that, else show first theme
            if (sharedTheme == "") {
                currentMapView = theMapViewArray[0].name;
                mapViewMenu.selectedIndex = 0;
            }
            else {
                var foundTheme:Boolean = false;
                for (i=0; i<theMapViewArray.length; i++) {
                    if (theMapViewArray[i].name == sharedTheme) {
                        currentMapView = sharedTheme;
                        mapViewMenu.selectedIndex = i;
                        foundTheme = true;
                        break;
                    }
                }
                if (!foundTheme) {
                    currentMapView = theMapViewArray[0].name;   //in case theme no longer a choice
                    mapViewMenu.selectedIndex = 0;
                }
            }
            mapViewsNodePresent = true;
            break;

        case "mapzooms":
            //add any extra zooms to the find area list
            if (theNode.attributes.defaultZoomId) {
                theDefaultMapZoomID = theNode.attributes.defaultZoomId;
            }
            else {
                theDefaultMapZoomID = "1"; //United States
            }
            for (i=0; i<theNode.childNodes.length; i++) {
                locationDataAC.push({areaID: theNode.childNodes[i].attributes.id, areaName: theNode.childNodes[i].attributes.label,
                                     areaXMin: theNode.childNodes[i].attributes.xmin, areaYMin:theNode.childNodes[i].attributes.ymin,
                                     areaXMax:theNode.childNodes[i].attributes.xmax, areaYMax: theNode.childNodes[i].attributes.ymax});
            }

            break;

        case "reports":
            //get reports node and save info if any defined
            for (i=0; i<theNode.childNodes.length; i++) {
                viewArray = new Array;
                viewObject = new ObjectProxy;

                theGroupNodes = theNode.childNodes[i].childNodes;
                for (j=0; j<theGroupNodes.length; j++) {
                    viewArray[j] = theGroupNodes[j].attributes.name;
                }
                viewObject.name = theNode.childNodes[i].attributes.name;
                viewObject.label = theNode.childNodes[i].attributes.label;
                viewObject.url = theNode.childNodes[i].attributes.url;
                viewObject.reportViews = viewArray;
                theReportArray.addItem(viewObject);

                //only add to reports menu if current view is in list of report views
                if (viewArray.indexOf(currentMapView) > -1) {
                    theReportMenuArray.addItem({name: viewObject.name, label: viewObject.label});
                }
            }
            if (theReportMenuArray.length > 0) {
                reportsMenu.selectedIndex = 0;
                reportsNodePresent = true;
            }
            break;

        case "links":
            //get links node and save info if any defined
            var linkObject:ObjectProxy;
            for (i=0; i<theNode.childNodes.length; i++) {
                linkObject = new ObjectProxy;

                linkObject.name = theNode.childNodes[i].attributes.name;
                linkObject.url = theNode.childNodes[i].attributes.url;
                theLinksArray.addItem(linkObject);
            }
            linksNodePresent = true;

            break;

        case "tools":
            //load tool views array
            for (i=0; i<theNode.childNodes.length; i++) {
                var toolArray:Array = new Array;
                var toolObject:ObjectProxy = new ObjectProxy;

                toolObject.toolName = theNode.childNodes[i].attributes.name;
                toolObject.toolLabel = theNode.childNodes[i].attributes.label;

                if (theNode.childNodes[i].attributes.name =="Identify") {
                    toolObject.identifyLinkFields = theNode.childNodes[i].attributes.linkFields;
                }
                else if (theNode.childNodes[i].attributes.name =="Find") {
                    toolObject.queryLayer = theNode.childNodes[i].attributes.layerName;
                    toolObject.queryLayerService = theNode.childNodes[i].attributes.layerService;
                    toolObject.queryLayerServiceFolder = theNode.childNodes[i].attributes.layerServiceFolder;
                    toolObject.querySearchFieldNames = theNode.childNodes[i].attributes.searchFieldNames;
                    toolObject.helpText = theNode.childNodes[i].attributes.helpText;
                }
                else if (theNode.childNodes[i].attributes.name =="Phenograph") {
                    toolObject.helpText = theNode.childNodes[i].attributes.helpText;
                }
                else if (theNode.childNodes[i].attributes.name =="ShareMap") {
                    toolObject.helpText = theNode.childNodes[i].attributes.helpText;
                }
                else if (theNode.childNodes[i].attributes.name =="TimeSlider") {
                    toolObject.helpText = theNode.childNodes[i].attributes.helpText;

                    var toolServiceArray:Array = new Array;
                    var toolServiceObject:ObjectProxy;

                    var theToolNodes:Array = theNode.childNodes[i].childNodes;
                    for (j=0; j<theToolNodes.length; j++) {
                        toolServiceObject = new ObjectProxy;
                        toolServiceObject.name = theToolNodes[j].attributes.name;
                        toolServiceObject.url = theToolNodes[j].attributes.url;
                        toolServiceObject.legendUrl = theToolNodes[j].attributes.legendUrl;
                        //toolServiceObject.dates = theToolNodes[j].attributes.dates;
                        toolServiceObject.label = theToolNodes[j].attributes.label;
                        toolServiceObject.type = theToolNodes[j].attributes.type;
                        toolServiceArray.push(toolServiceObject);
                    }
                    toolObject.toolServiceArray = toolServiceArray;
                }
                else if (theNode.childNodes[i].attributes.name =="Spatial Query") {
                    toolObject.bufferLayerName = theNode.childNodes[i].attributes.bufferLayerName;
                    toolObject.bufferLayerService = theNode.childNodes[i].attributes.bufferLayerService;
                    toolObject.bufferLayerServiceFolder = theNode.childNodes[i].attributes.bufferLayerServiceFolder;
                    toolObject.searchLayerName = theNode.childNodes[i].attributes.searchLayerName;
                    toolObject.searchLayerService = theNode.childNodes[i].attributes.searchLayerService;
                    toolObject.searchLayerServiceFolder = theNode.childNodes[i].attributes.searchLayerServiceFolder;
                    toolObject.querySearchFieldNames = theNode.childNodes[i].attributes.searchFieldNames;
                    toolObject.helpText = theNode.childNodes[i].attributes.helpText;
                }
                theToolViewArray.addItem(toolObject);
            }
            break;

        case "wmsLayers":
            //load WMS layers
            theWMSGroupArray = new Array;
            //var layerCounter:uint = 1000; //start WMS layers with 1000 to keep them separate from others
            for (i=0; i<theNode.childNodes.length; i++) {
                var groupNode:XMLNode                      = theNode.childNodes[i];
                var theWMSGroup:WMSGroup = new WMSGroup();
                theWMSGroup.name                  = groupNode.attributes.name;
                theWMSGroup.gid                   = groupNode.attributes.gid;
                theWMSGroup.label                 = groupNode.attributes.label;
                theWMSGroup.id                    = theLayerCounter;
                if (groupNode.attributes.selected == "true") {
                    this.selectedLayerAccordionGroupName = theWMSGroup.name;
                }

                //see if we define prior ESRI Service, if not, use default legend later
                if (groupNode.attributes.priorService) {
                    theWMSGroup.priorService = groupNode.attributes.priorService;
                }
                else {
                    theWMSGroup.priorService = "";
                }

                theLayerCounter++;
                var theWMSLayerArray:Array = new Array;

                for (j=0; j<groupNode.childNodes.length; j++) {
                    var wmsLayerOrSubgroupNode:XMLNode             = groupNode.childNodes[j];
                    if (wmsLayerOrSubgroupNode.localName == "wmsLayer") {
                        var theWMSLayerObject:ObjectProxy = createWMSLayerObject(theLayerCounter, -1, wmsLayerOrSubgroupNode);
                        theLayerCounter++;
                        theWMSLayerArray.push(theWMSLayerObject);
                    } else if (wmsLayerOrSubgroupNode.localName == "wmsSubgroup") {
                        var wmsSubgroup:WMSSubgroup = new WMSSubgroup();
                        wmsSubgroup.label        = wmsLayerOrSubgroupNode.attributes.label;
                        wmsSubgroup.id           = theLayerCounter;
                        wmsSubgroup.layerCounter = theLayerCounter;
                        theLayerCounter++;
                        theWMSLayerArray.push(wmsSubgroup);
                        for (var jj:uint=0; jj<wmsLayerOrSubgroupNode.childNodes.length; jj++) {
                            var node:XMLNode = wmsLayerOrSubgroupNode.childNodes[jj];
                            var theWMSLayerObject:ObjectProxy = createWMSLayerObject(theLayerCounter, wmsSubgroup.id, node);
                            theLayerCounter++;
                            wmsSubgroup.layers.push(theWMSLayerObject);
                        }
                    }
                }
                theWMSGroup.layers = theWMSLayerArray;
                theWMSGroupArray.push(theWMSGroup);
            }
            break;

        default:

        } //switch based on current node name
    } //over all config nodes

    //set tool visibility
    if (mapViewsNodePresent == false) {
        mapViewLabel.visible = false;
        mapViewMenu.visible = false;
        currentMapView = "";
    }
    if (reportsNodePresent == false) {
        reportsLabel.visible = false;
        reportsMenu.visible = false;
        reportsButton.visible = false;
    }
    if (linksNodePresent == false) {
        linksBar.visible = false;
    }

    if (theWMSGroupArray.length > 0) {
        loadWMSLayers(theWMSGroupArray, "");
    }
    theServiceCounter = 0;
    setInitialVisibleLayers();
}


private function createWMSLayerObject(thisLayerId:int, parentLayerId:int, wmsLayerNode:XMLNode):ObjectProxy {

    var theWMSLayerObject:ObjectProxy = new ObjectProxy;
    theWMSLayerObject.id              = thisLayerId;
    //theWMSLayerObject.parentLayerId   = theWMSAccordianGroup.id;
    theWMSLayerObject.parentLayerId   = parentLayerId;
    theWMSLayerObject.layerCounter    = thisLayerId;
    theWMSLayerObject.layers          = wmsLayerNode.attributes.layers;
    theWMSLayerObject.identify        = wmsLayerNode.attributes.identify;
    //theWMSLayerObject.name = wmsLayerNode.attributes.name;
    theWMSLayerObject.srs = wmsLayerNode.attributes.srs;

    //set URL - escape the & character
    var myPattern:RegExp = /&#38;/g;
    theWMSLayerObject.url = wmsLayerNode.attributes.url.replace(myPattern, "&");

    //see if we define layer name (for TOC) - if not, set layer name, and later we'll query capabilities to get it
    if (wmsLayerNode.attributes.name) {
        theWMSLayerObject.name = wmsLayerNode.attributes.name;
    }
    else {
        theWMSLayerObject.name = "";
    }

    if (wmsLayerNode.attributes.lid) {
        theWMSLayerObject.lid = wmsLayerNode.attributes.lid;
    } else {
        theWMSLayerObject.lid = "WLYR" + theWMSLayerObject.id;
    }


    //set if layer is visible
    if (sharedLayers != "") {
        if (layerIsShared(theWMSLayerObject.lid)) {
            theWMSLayerObject.visible = true;
        } else {
            theWMSLayerObject.visible = false;
        }
    } else {
        if (wmsLayerNode.attributes.visible == "true") {
            theWMSLayerObject.visible = true;
        } else {
            theWMSLayerObject.visible = false;
        }
    }

    /*xxxx
      if (wmsLayerNode.attributes.visible == "true") {
      theWMSLayerObject.visible = true;
      }
      else {
      theWMSLayerObject.visible = false;
      }
      xxxx*/


    theWMSLayerObject.styles = wmsLayerNode.attributes.styles;
    //see if we define legend, if not, use default legend later
    if (wmsLayerNode.attributes.legend) {
        theWMSLayerObject.legend = wmsLayerNode.attributes.legend;
    }
    else {
        theWMSLayerObject.legend = "";
    }

    return theWMSLayerObject;
}


private function addTools():void {
    //update tools
    for (var i:int=0; i<theToolViewArray.length; i++) {
        var toolName:String = theToolViewArray[i].toolName;
        var showTool:Boolean = isToolInView(toolName);

        //if tool is for this view, and it is missing, add it
        if ((showTool) && (!(toolsAccordion.getChildByName(toolName)))) {
            addTool(theToolViewArray[i]);
        }
        //if tool is not for this view, and it is present, remove it
        else if ((!showTool) && (toolsAccordion.getChildByName(toolName))) {
            toolsAccordion.removeChild(toolsAccordion.getChildByName(toolName));
        }
    }
}

private function addTool(toolObject:ObjectProxy):void {

    //include code for appropriate tool
    if (toolObject.toolName == "Print") {
        addPrintTool(toolObject);
    }
    else if (toolObject.toolName == "Export") {
        addExportTool(toolObject);
    }
    //else if (toolObject.toolName == "Find") {
    //addFindTool(toolObject);
    //}
    else if (toolObject.toolName == "TimeSlider") {
        addTimeSliderTool(toolObject);
    }
    else if (toolObject.toolName == "Phenograph") {
        addPhenographTool(toolObject);
    }
    else if (toolObject.toolName == "ShareMap") {
        addShareMapTool(toolObject);
    }
    //else if (toolObject.toolName == "Spatial Query") {
    //addSpatialQueryTool(toolObject);
    //}
}

private function changeSelectedTool(e:Event):void {
    currentMapTool = Accordion(e.target).selectedChild.name;
    if (currentMapTool == "Find") {
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "Print") {
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "Export") {
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "TimeSlider") {
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "Phenograph") {
        crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "Spatial Query") {
        crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
    }
    else if (currentMapTool == "ShareMap") {
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
        //update share URL
        updateShareURL();
    }
    else {
        CursorManager.removeAllCursors();
    }
    updateShareURL();
}

private function isToolInView(toolName:String):Boolean {
    return true;

    /*
    //see if this tool is valid for this view
    for (var i:uint=0; i<theToolViewArray.length; i++) {
    if (theToolViewArray[i].toolName == toolName) {
    //if no views, always return true
    if (theToolViewArray[i].toolViews.length == 0) {
    return true;
    }
    var theViewArray:Array = theToolViewArray[i].toolViews;
    break;
    }
    }

    if (theViewArray.indexOf(currentMapView) == -1)     {
    return false;
    }
    else {
    return true;
    }
    */
}

private function changeMapImage(event:ListEvent):void {

    //get selected extent
    var layerServiceName:String =  ComboBox(event.target).selectedItem.data;

    //update map layer
    var imageLayer:ArcGISTiledMapServiceLayer = ArcGISTiledMapServiceLayer(theMap.getLayer("tiledESRILayer"));
    imageLayer.url = ComboBox(event.target).selectedItem.url;

    //if user has share map tool open, update the URL
    updateShareURL();
}

private function changeMapView(event:ListEvent):void {

    /*xxxx
    //if user has share map tool open, update the URL
    updateShareURL();
    xxxx*/

    //set current map view
    currentMapView = ComboBox(event.target).selectedItem.name;
    var i:int;

    //set any map zoom linked to view
    for (i=0; i<theMapViewArray.length; i++) {
        if ((theMapViewArray[i].name == currentMapView) && (theMapViewArray[i].zoom == "yes")) {
            //get selected extent
            var xmin:Number =  theMapViewArray[i].xmin;
            var ymin:Number =  theMapViewArray[i].ymin;
            var xmax:Number =  theMapViewArray[i].xmax;
            var ymax:Number =  theMapViewArray[i].ymax;
            var wkid:int=  theMapViewArray[i].wkid;

            //make extent and set map extent
            var extent:Extent = new Extent(xmin,ymin,xmax,ymax,new SpatialReference(wkid));
            theMap.extent = extent.expand(1.1);

            //update menu of zooms
            //theMapZoomArray[0].label = theMapViewArray[i].label;
            //theMapZoomArray[0].name = theMapViewArray[i].name;
            //theMapZoomArray[0].reportField = theMapViewArray[i].reportField;
            //mapZoomMenu.dataProvider = theMapZoomArray;
            break;
        }
    }

    //clear map and legend
    for (i = (theMap.layerIds.length-1); i>0; i--) {
        theMap.removeLayer(theMap.getLayer(theMap.layerIds[i]));
    }
    theMapLayers.removeAll();
    theCurrentMapLayers.removeAll();
    layerAccordion.removeAllChildren();
    theLegendArray.removeAll();
    theTOCCanvasArray = new Array;

    //reload map with WMS layers
    //cursorManager.setBusyCursor();
    if (theWMSGroupArray.length > 0) {
        loadWMSLayers(theWMSGroupArray, "");
    }

    //update reports
    theReportMenuArray.removeAll();
    for (i=0; i<theReportArray.length; i++) {
        if (theReportArray[i].reportViews.indexOf(currentMapView) > -1) {
            theReportMenuArray.addItem({name: theReportArray[i].name, label: theReportArray[i].label, url: theReportArray[i].url});
        }
    }
    reportsLabel.visible = (theReportMenuArray.length > 0);
    reportsMenu.visible = (theReportMenuArray.length > 0);
    reportsButton.visible = (theReportMenuArray.length > 0);

    //get layers from service and load them
    theLayerCounter = 0;
    theServiceCounter = 0;
    setInitialVisibleLayers();

    //if user has share map tool open, update the URL
    updateShareURL();

}

private function runReport(evt:Event):void {
    var url:String = reportsMenu.selectedItem.url;
    var myURL:URLRequest = new URLRequest(url);
    navigateToURL(myURL, "_blank");
}

/*
  private function setWMSLayerTitles():void {

  // This function looks through all the WMS layers that we need to load (stored
  // in theWMSGroupArray), finds any whose "name" attribute is not yet set, and fetches
  // the WMS's GetCapabilities to look up the layer's "title", and sets the "name" attribute
  // to that title.  (This is confusing due to a poor choice of variable names in this code --- the
  // "name" attribute of a WMS layer in this code actually corresponds to the "title" of the layer
  // as specified in the service's GetCapabilities.)
  //
  // We use a temporary "cache" to make a list of all the GetCapabilities urls that will need to be
  // fetched, before fetching any of them, so that we fetch each one only once, and set
  // "name" attributes of all the layers that use that GetCapabilities url.

  var wmsTitleCache : Object = {};

  for (var groupCounter:int = 0; groupCounter<theWMSGroupArray.length; ++groupCounter) {
  for (var layerCounter:int = 0; layerCounter<theWMSGroupArray[groupCounter].layers.length; ++layerCounter) {
  if (theWMSGroupArray[groupCounter].layers[layerCounter].name == "") {
  if (wmsTitleCache[theWMSGroupArray[groupCounter].layers[layerCounter].url] != null) {
  wmsTitleCache[theWMSGroupArray[groupCounter].layers[layerCounter].url]['layers'].push(
  { 'groupCounter' : groupCounter, 'layerCounter' : layerCounter,
  'getCapName' : theWMSGroupArray[groupCounter].layers[layerCounter].layers
  }
  );
  } else {
  wmsTitleCache[theWMSGroupArray[groupCounter].layers[layerCounter].url] = {
  'layers' : [  { 'groupCounter' : groupCounter, 'layerCounter' : layerCounter,
  'getCapName' : theWMSGroupArray[groupCounter].layers[layerCounter].layers } ]
  };
  }
  }
  }
  }

  var multiLoader : MultiLoader = new MultiLoader();
  for (var url:String in wmsTitleCache) {
  trace('fetching getCap for ' + url);
  multiLoader.load(url + "&request=GetCapabilities&service=WMS",
  function(wmsTitleCache:Object):Function {
  return function(result:String):void {
  var resultXML : XML = new XML( result );
  for (var i:int = 0; i<wmsTitleCache[url].layers.length; ++i) {
  var groupCounter:int  = wmsTitleCache[url]['layers'][i]['groupCounter'];
  var layerCounter:int  = wmsTitleCache[url]['layers'][i]['layerCounter'];
  var getCapName:String = wmsTitleCache[url]['layers'][i]['getCapName'];
  var myQuery:XPathQuery = new XPathQuery("//Layer[Name='"+getCapName+"']/Title");
  myQuery.context.openAllNamespaces = true;
  var title : String = myQuery.exec(resultXML);
  //trace('setting wms['+groupCounter+']['+layerCounter+'].name = '+title);
  theWMSGroupArray[groupCounter].layers[layerCounter].name = title;
  }
  };
  }(wmsTitleCache)
  );
  }

  multiLoader.whenDone(function():void {
  loadWMSLayers(theWMSGroupArray, "");
  theServiceCounter = 0;
  setInitialVisibleLayers();
  });


  }
*/
private function loadWMSLayers(theWMSGroupArray:Array, priorService:String):void {
    if (theWMSGroupArray.length == 0) { return; }
    //loop over groups and add to map in reverse order to get them to draw correctly
    for (var i:int=(theWMSGroupArray.length-1); i>=0; i--) {
        //if this WMS group is not part of current view, skip it
        if ((currentMapView != "") && (currentMapView != null) && (!wmsGroupIsPartOfCurrentView(theWMSGroupArray[i].name))) {
            continue;
        }

        //if this WMS group does not come after the current priorService (passed in above), then skip it
        if (theWMSGroupArray[i].priorService != priorService) {
            continue
        }

        //add service
        addOneWMSService(theWMSGroupArray[i]);
    }
}

private function addOneWMSService(theWMSGroup:WMSGroup):void {
    var theWMSLayers:Array = theWMSGroup.layers;
    thisServiceName = theWMSGroup.name;

    //see if layers are empty
    if (theWMSLayers != null) {
        //get count and infos for layers in current service
        var theLayerCount:int = theWMSLayers.length;

        //return if service is empty
        if (theLayerCount > 0) {
            //add new Layer TOC pane to master layer accordion
            //make canvas for tool
            var c:Canvas = new Canvas;
            c.label = theWMSGroup.label;
            c.width = layerAccordion.width;
            c.height = layerAccordion.height;
            c.id = thisServiceName + "_Canvas";
            //c.name = thisServiceName + "_Canvas";
            //xxxgid:
            c.name = theWMSGroup.gid;
            //c.addEventListener(ResizeEvent.RESIZE, resizeGrid);

            //add TOC to canvas
            var toc:LayerTOC = new LayerTOC;
            toc.id = thisServiceName + "_LayerTOC";
            toc.name = thisServiceName + "_LayerTOC";
            toc.width = c.width*0.95;
            //toc.height = c.height*0.65;
            toc.serviceName = thisServiceName;
            toc.serviceFolder = thisServiceFolder;
            toc.addEventListener(ResizeEvent.RESIZE, toc.resizeTOC);
            c.addChildAt(toc,0);
            layerAccordion.addChildAt(c,0);
            theTOCCanvasArray.push(c);

            //go through layers in service - backwards, to get layers in right display order on map
            var thisServiceLayerArray:ArrayCollection = new ArrayCollection;
            theCurrentMapLayers.removeAll();
            //var WMSLayerObject:ObjectProxy;
            //var subLayerIDs:Array = new Array;
            //var infoArray:ObjectProxy;
            for (var i:int=(theLayerCount-1); i>=0; i--) {
                if (theWMSLayers[i] is WMSSubgroup) {
                    var wmsSubgroup:WMSSubgroup = theWMSLayers[i];
                    var subgroupArrayPosition = thisServiceLayerArray.length;
                    var sublayerIDs:Array = [];
                    for (var jj:int=(wmsSubgroup.layers.length-1); jj>=0; jj--) {
                        var infoArray:ObjectProxy = createWMSLayerInfoArray(wmsSubgroup.layers[jj], theWMSGroup.name);
                        sublayerIDs.push(infoArray.id);
                        theMapLayers.addItemAt(infoArray,0); //entire map
                        theCurrentMapLayers.addItemAt(infoArray,0); //for use when making legend
                        thisServiceLayerArray.addItemAt(infoArray,0); //just this TOC pane
                        theLayerCounter++;
                    }
                    var infoArray:ObjectProxy =  new ObjectProxy;
                    infoArray.id             = 0;
                    infoArray.layerCounter   = wmsSubgroup.layerCounter;
                    infoArray.mapId          = "GroupLayer" + thisServiceName;
                    infoArray.name           = wmsSubgroup.label; // text used for this subgroup's heading
                    infoArray.parentLayerId  = null;
                    infoArray.subLayerIds    = sublayerIDs;
                    infoArray.visible        = false;
                    infoArray.serviceName    = theWMSGroup.name;
                    infoArray.transparency   = 0;
                    infoArray.type           = "WMS";
                    theMapLayers.addItemAt(infoArray,0); //entire map
                    thisServiceLayerArray.addItemAt(infoArray,0); //just this TOC pane
                } else {
                    var wmsLayerObject:ObjectProxy = theWMSLayers[i];
                    var infoArray:ObjectProxy = createWMSLayerInfoArray(wmsLayerObject, theWMSGroup.name);
                    theMapLayers.addItemAt(infoArray,0); //entire map
                    theCurrentMapLayers.addItemAt(infoArray,0); //for use when making legend
                    thisServiceLayerArray.addItemAt(infoArray,0); //just this TOC pane
                    theLayerCounter++;
                }
            }
            /*
            //add parent layer (serves as a heading for the "subgroup" in the accordian section)
            infoArray                = new ObjectProxy;
            infoArray.id             = 0;
            infoArray.layerCounter   = WMSLayerObject.layerCounter;
            infoArray.mapId          = "GroupLayer" + thisServiceName;
            infoArray.name           = theWMSAccordianGroup.label; // text used for this subgroup's heading
            infoArray.parentLayerId  = null;
            infoArray.subLayerIds    = subLayerIDs;
            infoArray.visible        = false;
            infoArray.serviceName    = theWMSAccordianGroup.name;
            infoArray.transparency   = 0;
            infoArray.type           = "WMS";
            theMapLayers.addItemAt(infoArray,0); //entire map
            thisServiceLayerArray.addItemAt(infoArray,0); //just this TOC pane
            */
            toc.layerArray = thisServiceLayerArray;

            //build legend
            buildWMSLegend(theCurrentMapLayers.length);

        } //if layer count > 0
    } // if layers are not null

}

private function createWMSLayerInfoArray(wmsLayerObject:ObjectProxy, serviceName:String):ObjectProxy {

    //get copy of service and set only current layer to be visible
    var theWMSLayer:WMSMapServiceLayer = new WMSMapServiceLayer(wmsLayerObject.url, wmsLayerObject.srs);
    theWMSLayer.wmsLayers = wmsLayerObject.layers;
    theWMSLayer.styles = wmsLayerObject.styles;
    theWMSLayer.id = "WMS_Layer" + wmsLayerObject.id;

    /*xxxx
      trace('createWMSLayerInfoArray');
      // if there are shared layers at all in the URL, set this layer's visibility based on
      // whether the URL says it should be visible:
      if (sharedLayers != "") {
      if (sharedLayers.indexOf(theWMSLayer.id+",") >= 0) {
      theWMSLayer.visible = true;
      }
      else {
      theWMSLayer.visible = false;
      }
      } else { // otherwise, set visibility based on config file
      theWMSLayer.visible = wmsLayerObject.visible;
      }
      xxxx*/

    theWMSLayer.visible = wmsLayerObject.visible

    theMap.addLayer(theWMSLayer);

    //save layer info for legend
    var infoArray:ObjectProxy = new ObjectProxy;
    infoArray.id = wmsLayerObject.id;
    infoArray.lid = wmsLayerObject.lid;
    infoArray.layerCounter = wmsLayerObject.layerCounter;
    infoArray.mapId = theWMSLayer.id;
    infoArray.name = wmsLayerObject.name;
    infoArray.parentLayerId = wmsLayerObject.parentLayerId;
    infoArray.subLayerIds = null;
    infoArray.visible = theWMSLayer.visible;
    infoArray.serviceName = serviceName;

    if ((sharedLayers != "") && (sharedAlphas != "")) {
        if (layerIsShared(wmsLayerObject.lid)) { // xxx was .id ???
            var sharedLayersArray:Array = sharedLayers.split(",");
            var sharedAlphasArray:Array = sharedAlphas.split(",");
            theWMSLayer.alpha = sharedAlphasArray[sharedLayersArray.indexOf(wmsLayerObject.lid)];
            infoArray.transparency = (1 - theWMSLayer.alpha) * 100;
        }
    }
    else {
        infoArray.transparency = 0;
    }

    infoArray.type = "WMS";
    if (wmsLayerObject.identify == "true") {
        infoArray.identifyFlag = true;
    }
    else {
        infoArray.identifyFlag = false;
    }
    infoArray.settingsWindowOpen = false;
    infoArray.legend = wmsLayerObject.legend;
    infoArray.url = wmsLayerObject.url;
    infoArray.srs = wmsLayerObject.srs;
    infoArray.layer = wmsLayerObject.layers;

    return infoArray;
}

private function wmsGroupIsPartOfCurrentView(wmsGroupName:String):Boolean {
    var returnValue:Boolean = false

    //now see if parent group is part of array for current view
    for (var i:int=0;i<theMapViewArray.length;i++) {
        if (theMapViewArray[i].name == currentMapView) {
            var theViewGroups:Array = theMapViewArray[i].layerGroups;
            if (theViewGroups.indexOf(wmsGroupName) >= 0) {
                returnValue = true;
                break;
            }
        }
    }

    return returnValue;
}

private function serviceIsPartOfCurrentView(serviceName:String):Boolean {
    var returnValue:Boolean = false;

    //see if current service iss part of array for current view
    for (var i:int=0;i<theMapViewArray.length;i++) {
        if (theMapViewArray[i].name == currentMapView) {
            var theViewGroups:Array = theMapViewArray[i].layerGroups;
            if (theViewGroups.indexOf(serviceName) >= 0) {
                returnValue = true;
                break;
            }
        }
    }

    return returnValue;
}

private function layerIsPartOfCurrentView(info:LayerInfo):Boolean {
    var returnValue:Boolean = false;

    //get parent group name of current layer (or just name, if it's a parent group)
    var parentGroupName:String;
    if (info.parentLayerId == -1) {
        parentGroupName = info.name;
    }
    else {
        parentGroupName = layerInfos[info.parentLayerId].name;
    }

    //now see if parent group is part of array for current view
    for (var i:int=0;i<theMapViewArray.length;i++) {
        if (theMapViewArray[i].name == currentMapView) {
            var theViewGroups:Array = theMapViewArray[i].layerGroups;
            if (theViewGroups.indexOf(parentGroupName) >= 0) {
                returnValue = true;
                break;
            }
        }
    }

    return returnValue;
}

private function setInitialVisibleLayers():void {
    thisServiceName = theServiceNameArray[theServiceCounter].name;

    //see if service is part of group in current view or not - if not, skip service
    //if we have no views, current view is empty string, so don't test
    if ((currentMapView == "") || (serviceIsPartOfCurrentView(thisServiceName))) {
        thisServiceFolder = theServiceNameArray[theServiceCounter].folder;
        var theServiceURL:String = theMapServerPath + "rest/services/" + thisServiceFolder + "/" + thisServiceName + "/MapServer";
        theLayers = new ArcGISDynamicMapServiceLayer(theServiceURL);
        theLayers.addEventListener(LayerEvent.LOAD, addOneService);
    }
    else {
        gotoNextService();
    }
}

private function addOneService(evt:LayerEvent):void {

    //see if layers are empty
    if ((theLayers != null) && (theLayers.layerInfos != null)) {
        //get count and infos for layers in current service
        layerInfos = theLayers.layerInfos;
        var theLayerCount:int = layerInfos.length;

        //return if service is empty
        if (theLayerCount > 0) {
            //add new Layer TOC pane to master layer accordion
            //make canvas for tool
            var c:Canvas = new Canvas;
            c.label = theServiceNameArray[theServiceCounter].label;
            c.width = layerAccordion.width;
            c.height = layerAccordion.height;
            c.id = thisServiceName + "_Canvas";
            c.name = thisServiceName + "_Canvas";


            //add TOC to canvas
            var toc:LayerTOC = new LayerTOC;
            toc.id = thisServiceName + "_LayerTOC";
            toc.name = thisServiceName + "_LayerTOC";
            toc.width = c.width*0.95;
            //toc.height = c.height*0.65;
            toc.serviceName = thisServiceName;
            toc.serviceFolder = thisServiceFolder;
            toc.addEventListener(ResizeEvent.RESIZE, toc.resizeTOC);
            c.addChildAt(toc,0);
            layerAccordion.addChildAt(c,0);
            theTOCCanvasArray.push(c);

            //go through layers in service - backwards, to get layers in right display order on map
            var info:LayerInfo;
            var thisServiceLayerArray:ArrayCollection = new ArrayCollection;
            theCurrentMapLayers.removeAll();

            for (var i:int=(theLayerCount-1); i>=0; i--) {
                info = layerInfos[i];

                //get copy of service and set only current layer to be visible
                var theServiceURL:String = theMapServerPath + "rest/services/" + thisServiceFolder + "/" + thisServiceName + "/MapServer";
                var thisLayer:ArcGISDynamicMapServiceLayer = new ArcGISDynamicMapServiceLayer(theServiceURL);
                thisLayer.id = thisServiceName+"_Layer"+i;
                var visibleLayers:ArrayCollection = thisLayer.visibleLayers;

                if (visibleLayers == null) {
                    visibleLayers = new ArrayCollection;
                }
                if (visibleLayers.length > 0) {
                    visibleLayers.removeAll();
                }
                visibleLayers.addItem(i);
                thisLayer.visibleLayers = visibleLayers;

                var infoArray:ObjectProxy = new ObjectProxy;
                infoArray.lid = thisLayer.id;

                //if we have shared layers in URL, see if this layer is visible
                if (sharedLayers != "") {
                    if (layerIsShared(thisLayer.id)) { // if (sharedLayers.indexOf(thisLayer.id+",") >= 0) {
                        thisLayer.visible = true;
                    }
                    else {
                        thisLayer.visible = false;
                    }
                }
                else {
                    //check default visibility; also make all group layers be OFF
                    if ((info.defaultVisibility == false) || (!(info.subLayerIds == null))) {
                        thisLayer.visible = false;
                    }
                }

                //add layer to map
                theMap.addLayer(thisLayer);

                //save layer info in array for binding

                infoArray.id = info.id;
                infoArray.mapId = thisLayer.id;
                infoArray.name = info.name;
                infoArray.parentLayerId = info.parentLayerId;
                infoArray.subLayerIds = info.subLayerIds;
                infoArray.visible = thisLayer.visible;

                if ((sharedLayers != "") && (sharedAlphas != "")) {
                    if (layerIsShared(thisLayer.id)) { // if (sharedLayers.indexOf(thisLayer.id+",") >= 0) {
                        var sharedLayersArray:Array = sharedLayers.split(",");
                        var sharedAlphasArray:Array = sharedAlphas.split(",");
                        thisLayer.alpha = sharedAlphasArray[sharedLayersArray.indexOf(thisLayer.id)];
                        infoArray.transparency = (1 - thisLayer.alpha) * 100;
                    }
                }
                else {
                    infoArray.transparency = 0;
                }

                infoArray.serviceName = thisServiceName;
                infoArray.serviceFolder= thisServiceFolder;
                infoArray.layerCounter = theLayerCounter;
                infoArray.identifyFlag = true;
                infoArray.settingsWindowOpen = false;

                theMapLayers.addItemAt(infoArray,0); //entire map
                theCurrentMapLayers.addItemAt(infoArray,0); //for use when making legend
                thisServiceLayerArray.addItemAt(infoArray,0); //just this TOC pane
                theLayerCounter++;
            }
            toc.layerArray = thisServiceLayerArray;

            //var mapinfoArray:ObjectProxy = new ObjectProxy;
            //mapinfoArray.mapArray = theMapLayers;
            //mapinfoArray.serviceName = thisServiceName;

            //build legend
            if (legendType == "WMS") {
                buildWMSLegend(theCurrentMapLayers.length);
            }
            else if (legendType == "Image") {
                buildImageLegend(theCurrentMapLayers.length);
            }

            //load any WMS layers that come after this service (above in layer list)
            loadWMSLayers(theWMSGroupArray, thisServiceName);

        } //if layer count > 0
    } // if layers are not null

    //do next service
    gotoNextService();
}

private function gotoNextService():void {

    //go to next service
    theServiceCounter++;
    if (theServiceCounter < theServiceNameArray.length) {
        setInitialVisibleLayers();
    }
    else {
        reallyHideESRILogo(theMap);
        cursorManager.removeBusyCursor();
        finishMapLoading();
    }
}

private function finishMapLoading():void {
    //always runs last after layers loaded

    if (currentState == "Printing") {

        //resize map for needed printing - pass size and orientation
        resizeMapForPrinting(sharedPrint.split(",")[0], sharedPrint.split(",")[1]);

    }
    else {

        //add tools (done after the layers so Find and Identify graphic layers are on top)
        //crosshairCursorID = CursorManager.setCursor(crosshairCursor,2,-8.5,-8.5);
        addIdentifyTool(); // always present, add first
        addTools(); // add any tools in config file

        //add graphics layer to top for drawing
        theMap.addLayer(drawingGraphicsLayer);

        /*
        //show multigraph if defined in URL
        if (sharedMultigraph != "") {
        //open multigraph for the points
        phenographOpenFromSharedURL(sharedMultigraph);
        }
        */
    }
    /*xxxx*/
    if (!actionsToBeDoneOnceUponStartupAfterMapLoadingDone) {
        doActionsToBeDoneOnceUponStartupAfterMapLoading();
    }
    updateShareURL();

}

private function doActionsToBeDoneOnceUponStartupAfterMapLoading():void {
    ///
    /// Force open the correct layer accordian group --- either the one specified in the share URL, if any, or the
    /// one marked as selected="true" in the config file, if any.  For each possbility (shared/selected), check
    /// both for an accordian group with the given name, and with the given name with "_Canvas" appended.
    /// The reason for this is just to be thorough; at the time that I (mbp) am writing this, the internal accordion
    /// group (Canvas) names have "_Canvas" appended to them.  I might remove the "_Canvas" suffix from the internal name
    /// at some point in the future if I can determine that there are no dependencies on it, but for now
    /// I am leaving it, just in case.  I don't want to include it in the "accgp" value included in the share URL,
    /// though, so I'm omitting it there.  This creates a certain amount of confusion about places where the
    /// name has the _Canvas suffix vs places where it does not.  Hence the inspiration for this probably-overkill
    /// checking here.
    ///
    var accgp:INavigatorContent = (INavigatorContent)(layerAccordion.getChildByName(sharedLayerAccordionGroupName)); // sharedLayerAccordionGroupName without _Canvas suffix
    if (accgp == null) {
        accgp = (INavigatorContent)(layerAccordion.getChildByName(sharedLayerAccordionGroupName+"_Canvas")); // sharedLayerAccordionGroupName with _Canvas suffix
    }
    if (accgp == null) {
        accgp = (INavigatorContent)(layerAccordion.getChildByName(selectedLayerAccordionGroupName));  // selectedLayerAccordionGroupName without _Canvas suffix
    }
    if (accgp == null) {
        accgp = (INavigatorContent)(layerAccordion.getChildByName(selectedLayerAccordionGroupName+"_Canvas")); // selectedLayerAccordionGroupName with _Canvas suffix
    }
    if (accgp != null) {
        layerAccordion.selectedChild = accgp;
    }

    /**
     *  If the getChildByName method still has not returned a selected
     *  accordion pane, loop through all accordion children and compare
     *  their IDs to the selected layer group defined in the config file.
     *  If a layer group matches, set the selected accordion member by
     *  index number.
     **/
    if(accgp == null){
        var layerAccordionChildren:Array = layerAccordion.getChildren();
        var childIndex:int = 0;
        for(var i:int = 0; i<layerAccordionChildren.length; i++){
            if(layerAccordionChildren[i].id == selectedLayerAccordionGroupName+"_Canvas"){
                childIndex = i;
                break;
            }
        }
        layerAccordion.selectedIndex = childIndex;
    }

    actionsToBeDoneOnceUponStartupAfterMapLoadingDone = true;
}


private function buildWMSLegend(theLayerCount:int):void {

    if (theCurrentMapLayers.length == 0) { return };

    //set up variable for WMS legend images
    var legendUrlPrefix:String;
    legendUrlPrefix = theLegendServerPath + "arcgisoutput/" + thisServiceFolder + "_" + thisServiceName + "_MapServer/wms/default";

    //build array of objects for legend
    for (var i:int=(theLayerCount-1); i>=0; i--) {
        if (theCurrentMapLayers[i].visible == true)  {
            var legendInfo:ObjectProxy = new ObjectProxy;
            legendInfo.id = theCurrentMapLayers[i].id;
            if (theCurrentMapLayers[i].type == "ESRI") {
                var theFullLayerCount:int = layerInfos.length;
                legendInfo.src = legendUrlPrefix + (theFullLayerCount - theCurrentMapLayers[i].id) + ".png"
            }
            else if (theCurrentMapLayers[i].type == "WMS") {
                legendInfo.src = theCurrentMapLayers[i].legend;
            }
            legendInfo.id = theCurrentMapLayers[i].id;
            legendInfo.name = theCurrentMapLayers[i].name;
            legendInfo.mapId = theCurrentMapLayers[i].mapId;
            legendInfo.layerCounter = theCurrentMapLayers[i].layerCounter;
            legendInfo.serviceName = thisServiceName;
            theLegendArray.addItemAt(legendInfo,0);
        }
    }
}

private function buildImageLegend(theLayerCount:int):void {

    if (theCurrentMapLayers.length == 0) { return };

    //set up variable for WMS legend images
    var legendUrlPrefix:String =  theLegendServerPath + thisServiceFolder + "/" + thisServiceName + "/";

    //clear legend

    //build array of objects for legend
    var info:LayerInfo;
    //var theLayerCount:int = theMapLayers.length;
    var addLegend:Boolean;
    var memberOfLegendGroup:Boolean;
    var memberLegendGroupLayerID:uint;
    var memberOfLayerGroup:Boolean;
    var memberLayerGroup:String;

    for (var i:int=(theLayerCount-1); i>=0; i--) {
        info = layerInfos[i];
        addLegend = false;
        memberOfLegendGroup = false;
        memberOfLayerGroup = false;

        //add legend if layer is visible
        if (theCurrentMapLayers[i].visible == true)  {

            //is layer stand alone? if so add legend
            if (info.parentLayerId == -1) {
                addLegend = true;  //not part of any group
            }
            else {
                //first test against legend group
                var parentInfo:LayerInfo = layerInfos[info.parentLayerId];

                //first see if layer belongs to a layer group
                for (j=0; j<theLayerGroupArray.length; j++) {
                    var layerGroupName:String = theLayerGroupArray[j];
                    //if (theLayerInfoObject.name.slice((0-layerGroupName.length), theLayerInfoObject.name.length) == layerGroupName) {
                    if (info.name.split(layerGroupName).length > 1) {
                        memberOfLayerGroup = true;
                        memberLayerGroup = layerGroupName;
                        break;
                    } //see if current layer is in layer group
                } //loop over all layer groups

                //if not part of a layer group, see if layer belongs to a legend group
                if (memberOfLayerGroup == false) {
                    memberOfLegendGroup = (theLegendGroupArray.getItemIndex(parentInfo.name) != -1);
                }

                //now test if legend for layer needs to be on
                if ((memberOfLayerGroup == false) && (memberOfLegendGroup == false)) {
                    addLegend = true;  //not part of a legend group or layer group
                }
                else if (memberOfLayerGroup) {
                    addLegend = true;
                    //now see if any other layers with same layer name are turned on
                    //now see if any other layers with same layer name are turned on
                    for (var k:int=0;k<theLayerCount; k++) {
                        if (theCurrentMapLayers[k].name != info.name) {
                            if (theCurrentMapLayers[k].name.slice((0-layerGroupName.length), theCurrentMapLayers[k].name.length) == layerGroupName) {
                                if (theCurrentMapLayers[k].visible == true) {
                                    addLegend = false; //another layer in legend group is visible
                                    break;
                                } //layer is visible
                            } // map layer is part of same layer group
                        } //if layer is not current layer we're testing
                    } //each layer
                }
                else if (memberOfLegendGroup) {
                    addLegend = true;
                    memberLegendGroupLayerID = info.parentLayerId;
                    //now see if any other layers in same legend group are turned on
                    for (var j:int=0; j<parentInfo.subLayerIds.length; j++) {
                        if (info.name != theCurrentMapLayers[parentInfo.subLayerIds[j]].name) {
                            if (theCurrentMapLayers[j].visible == true) {
                                addLegend = false; //another layer in legend group is visible
                                break;
                            } //layer is visible
                        } //sublayer is not current layer in main loop
                    } //each layer in group
                } //layer is part of a legend group
            } //layer has parent (is part of a group layer - group layers do not have legends)
        } //map layer visible

        if (addLegend == true) {
            var legendInfo:ObjectProxy = new ObjectProxy;
            legendInfo.id = theCurrentMapLayers[i].id;
            legendInfo.name = theCurrentMapLayers[i].name;
            legendInfo.mapId = theCurrentMapLayers[i].mapId;
            legendInfo.layerCounter = theCurrentMapLayers[i].layerCounter;
            legendInfo.serviceName = thisServiceName;
            legendInfo.serviceFolder = thisServiceFolder;

            //if part of a layer group, we need to use that group name to build the image url
            if (memberOfLayerGroup == true) {
                legendInfo.src = legendUrlPrefix + memberLayerGroup.replace(/ /g, "_") + ".PNG";
                legendInfo.groupType = "Layer";
                legendInfo.groupLayer = memberLayerGroup;
            }
            else if (memberOfLegendGroup == true) { //use legend group name
                legendInfo.src = legendUrlPrefix + parentInfo.name.replace(/ /g, "_") + ".PNG";
                legendInfo.groupType = "Legend";
                legendInfo.groupLayer = memberLegendGroupLayerID;
            }
            else { //just use layer name
                legendInfo.src = legendUrlPrefix + theCurrentMapLayers[i].name.replace(/ /g, "_") + ".PNG";
                legendInfo.groupType = "None";
            }

            theLegendArray.addItemAt(legendInfo,0);
        } //if we add legend

    } //for each layer

}

//generic fault
private function fault(evt:FaultEvent):void {
    Alert.show(evt.fault.message);
}
