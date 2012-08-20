package edu.unca.nemac.gisviewer
{
	import com.esri.ags.layers.DynamicMapServiceLayer;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;

	public class WMSMapServiceLayer extends DynamicMapServiceLayer
	{
		internal const service:String = "WMS";
		internal const version:String = "1.1.1";
		internal const request:String = "GetMap";
		internal const format:String = "image/png";
		internal const scalar:Number = 1;
		
		public var wmsLayers:String;
		public var serviceName:String;
		
		public var wmtVersion:String;
		public var styles:String = "";
		public var srs:String = "EPSG:4326";
		//public var srs:String = "EPSG:102100";
		//public var srs:String = "EPSG:3785";
		public var url:String;
		//public var transparentBG:String = "false";
		
		public var throwsComplete:String;
		//public var proxyURL:String;
		
		public function WMSMapServiceLayer(url:String,srs:String)
		{
			super();
			this.setLoaded(true);
			this.url = url;
			this.srs = srs;
		}
		
		

		override protected function loadMapImage(loader:Loader):void {

			
			
			var pxWidth:Number = Math.floor(this.map.width * scalar);
			var pxHeight:Number = Math.floor(this.map.height * scalar);
			
			
			var index : int = url.indexOf( "?");
			var prefix : String = index == -1 ? "?" : "&";			
			var _url:String = url;
			_url += prefix + "SERVICE="+service;
			_url += "&VERSION="+version;
			_url += "&REQUEST="+request;
			
			if( serviceName != null) {
				_url += "&SERVICENAME="+serviceName;
			}
			if( wmtVersion != null) {
			 	_url += "&WMTVER="+wmtVersion;
			}
			if( wmsLayers != null) {
			
			 	_url += "&LAYERS="+wmsLayers;
			}
			//if( styles != null) {
				_url += "&STYLES="+styles;
			//}
			
			//if(transparentBG != null) {
			//	_url += "&TRANSPARENT="+transparentBG;
			//}
			
			if( srs != null) {
				_url += "&SRS="+srs;
			}
			_url += "&FORMAT="+format;
			_url += "&WIDTH="+pxWidth;
			_url += "&HEIGHT="+pxHeight;
			_url += "&BBOX="+this.map.extent.xmin+","+this.map.extent.ymin+","+this.map.extent.xmax+","+this.map.extent.ymax;
		
			var wmsReq:URLRequest = new URLRequest(_url);
	/*		
			if( proxyURL != null)
			{
			 _url = proxyURL + "?" + escape( _url);
			}
	*/
	
		// Don't want to throw this for all.

			loader.addEventListener("complete",sendEvent);

			loader.load(wmsReq);
			
			
		}
		
		private function sendEvent(event:Event):void {		

			if(throwsComplete == "true") {
				
				this.dispatchEvent(new Event("wmsbase"));
			}
			
		}
		
	} // class

} //package

