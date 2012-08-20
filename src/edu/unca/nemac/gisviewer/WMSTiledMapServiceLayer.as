package edu.unca.nemac.gisviewer
{
	
	// Author: Steve.Ansari@noaa.gov
	// This extends the TiledMapServiceLayer in the ArcGIS Flex API to provide
	// WMS support.  The WMS extents are calculated from the Level of Detail (LOD)
	// resolutions and tile origin.
	
import com.esri.ags.SpatialReference;
import com.esri.ags.geometry.Extent;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.layers.LOD;
import com.esri.ags.layers.TileInfo;
import com.esri.ags.layers.TiledMapServiceLayer;

import flash.net.URLRequest;

import mx.formatters.NumberFormatter;

	public class WMSTiledMapServiceLayer extends TiledMapServiceLayer
	{
		
		internal const service:String = "WMS";
        internal const version:String = "1.1.1";
        internal const request:String = "GetMap";
        internal const scalar:Number = 1;
        
        public var format:String = "image/png";
        public var wmsLayer:String;
        public var serviceName:String;
        
        public var wmtVersion:String;
        public var styles:String = "";
        public var srs:String = "EPSG:4326";
        public var url:String;
        //public var transparentBG:String;
        
        public var time:String;
		
		
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Creates a new WMSTiledMapServiceLayer object.
     */
    public function WMSTiledMapServiceLayer(url:String,srs:String)
    {
        super();
        
        buildTileInfo(); // to create our hardcoded tileInfo 
        
        setLoaded(true); // Map will only use loaded layers
        
        this.url = url;
        this.srs = srs;
        this.wmsLayer = wmsLayer
        this.format = format;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    private var _tileInfo:TileInfo = new TileInfo();  // see buildTileInfo() 
/*       private var _baseURL:String = "http://sampleserver1.arcgisonline.com/arcgiscache/Portland_Portland_ESRI_LandBase_AGO/Portland/_alllayers"; */    
    
    //--------------------------------------------------------------------------
    //
    //  Overridden properties
    //      fullExtent()
    //      initialExtent()
    //      spatialReference()
    //      tileInfo()
    //      units()
    //
    //--------------------------------------------------------------------------

    
    //----------------------------------
    //  fullExtent
    //  - required to calculate the tiles to use
    //----------------------------------

    override public function get fullExtent():Extent
    {
        return new Extent(-180, -90, 180, 90, new SpatialReference(4326));
    }
    
    //----------------------------------
    //  initialExtent
    //  - needed if Map doesn't have an extent
    //----------------------------------

    override public function get initialExtent():Extent
    {
        return new Extent(-180, -90, 180, 90, new SpatialReference(4326));
    }

    //----------------------------------
    //  spatialReference
    //  - needed if Map doesn't have a spatialReference
    //----------------------------------

    override public function get spatialReference():SpatialReference
    {
        return new SpatialReference(4326);
    }

    //----------------------------------
    //  tileInfo
    //----------------------------------

    override public function get tileInfo():TileInfo
    {
        return _tileInfo;
    }

    //----------------------------------
    //  units
    //  - needed if Map doesn't have it set
    //----------------------------------

    override public function get units():String
    {
        return "esriDecimalDegrees";
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //      getTileURL(level:Number, row:Number, col:Number):URLRequest
    //
    //--------------------------------------------------------------------------

    override protected function getTileURL(level:Number, row:Number, col:Number):URLRequest
    {

 		var requestUrl:String = this.url;
 		
 		var pxWidth:Number = 512;
 		var pxHeight:Number = 512;
 		
            var index : int = url.indexOf( "?");
            var prefix : String = index == -1 ? "?" : "&";    
            requestUrl += prefix + "SERVICE="+service;
            requestUrl += "&VERSION="+version;
            requestUrl += "&REQUEST="+request;
            // For many WMS servers, SERVICENAME and others are unused, but some must be included or the server will reject our request. For example STYLES.
            if( serviceName != null) {
                requestUrl += "&SERVICENAME="+serviceName;
            }
            if( wmtVersion != null) {
                 requestUrl += "&WMTVER="+wmtVersion;
            }
            if( wmsLayer != null) {
                 requestUrl += "&LAYERS="+wmsLayer;
            }
            requestUrl += "&STYLES="+styles;
            //if(transparentBG != null) {
                //requestUrl += "&TRANSPARENT="+transparentBG;
            //}
            if( srs != null) {
                requestUrl += "&SRS="+srs;
            }
            
            if( time != null) {
            	if ( time == "yesterday" ) {
            		time=getInitialTimeString();	
            	}
            	
            	requestUrl += "&TIME="+time;
            }
            requestUrl += "&FORMAT="+format;
            requestUrl += "&WIDTH="+pxWidth;
            requestUrl += "&HEIGHT="+pxHeight;
/*             requestUrl += "&BBOX="+this.map.extent.xmin+","+this.map.extent.ymin+","+this.map.extent.xmax+","+this.map.extent.ymax;
 */ 			     
 			var myLod:LOD = _tileInfo.lods[level];
 			var xMin:Number = _tileInfo.origin.x + col*(myLod.resolution*_tileInfo.width) ; 
 			var xMax:Number = _tileInfo.origin.x + (col+1)*(myLod.resolution*_tileInfo.width) ; 
 			var yMin:Number = _tileInfo.origin.y - (row+1)*(myLod.resolution*_tileInfo.height) ; 
 			var yMax:Number = _tileInfo.origin.y - row*(myLod.resolution*_tileInfo.height) ; 

           requestUrl += "&BBOX="+xMin.toFixed(6)+","+yMin.toFixed(6)+","+xMax.toFixed(6)+","+yMax.toFixed(6);
           
/*            
 			trace(level+" , "+row+" , "+col);
 			trace(requestUrl); 			
 */ 			
            
        return new URLRequest(requestUrl);
    }
    
    //--------------------------------------------------------------------------
    //
    //  Private Methods
    //
    //--------------------------------------------------------------------------

    private function buildTileInfo():void
    {
        _tileInfo.height = 512;
        _tileInfo.width = 512;
        _tileInfo.origin = new MapPoint(-180, 90);
        _tileInfo.spatialReference = new SpatialReference(4326);
        _tileInfo.lods = [
			new LOD(0, 0.351562499999999, 147748799.285417),
			new LOD(1, 0.17578125, 73874399.6427087),
			new LOD(2, 0.0878906250000001, 36937199.8213544),
			new LOD(3, 0.0439453125, 18468599.9106772),
			new LOD(4, 0.02197265625, 9234299.95533859),
			new LOD(5, 0.010986328125, 4617149.97766929),
			new LOD(6, 0.0054931640625, 2308574.98883465),
			new LOD(7, 0.00274658203124999, 1154287.49441732),
			new LOD(8, 0.001373291015625, 577143.747208662),
			new LOD(9, 0.0006866455078125, 288571.873604331),
			new LOD(10, 0.000343322753906249, 144285.936802165),
			new LOD(11, 0.000171661376953125, 72142.9684010827),
			new LOD(12, 0.0000858306884765626, 36071.4842005414),
			new LOD(13, 0.0000429153442382813, 18035.7421002707),
			new LOD(14, 0.0000214576721191406, 9017.87105013534),
			new LOD(15, 0.0000107288360595703, 4508.93552506767)
        ];
    }

    private function padString(text:String, size:int, ch:String):String
    {
        while (text.length < size)
        {
            text = ch + text;
        }
        return text;
    }
    
            public function getInitialTimeString():String {
            	var yest:Date = new Date(new Date().time-(1000*60*60*24));
            	
            	var str:String = yest.fullYear+"-"+
            		zeroPad(yest.month, 2)+"-"+
            		zeroPad(yest.date, 2)+
            		"T00:00:00Z";
            	           		
            	return str;
            }
            
            public function zeroPad(number:int, width:int):String {
   				var ret:String = ""+number;
   				while( ret.length < width ) {
       				ret="0" + ret;
       			}
   				return ret;
			}
}

}
