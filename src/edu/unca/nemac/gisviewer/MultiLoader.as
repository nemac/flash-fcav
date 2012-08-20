package edu.unca.nemac.gisviewer
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import memorphic.xpath.XPathQuery;

    /**
     * A MultiLoader is a kind of URL loader that has the ability to load
     * multiple URLs asynchronously, and then call a single completion function
     * when all of them have finished loading (or have failed).  Use it like this:
     * 
     *     var m : MultiLoader = new MultiLoader();
     *     m.load(url1, function(content:String):void {...});
     *     m.load(url2, function(content:String):void {...});
     *     m.load(url3, function(content:String):void {...});
     *     ...
     *     m.whenDone( function():void {...} );
     * 
     * The second parameter to the load() method is a function that will be
     * called with the URL passed as the first parameter has finished loading;
     * the function takes a single String argument which is the content of the
     * response for that URL.  Then whenDone(...) method takes a single function
     * argument; that function will be called after all the urls specified in
     * calls to load() have finished loading (and their corresponding content
     * processing functions called).
     *
     * You should not call whenDone() until after you have called load()
     * for every URL you want loaded.  Don't call load() after calling whenDone().
     *
     * Mark Phillips
     * Thu Mar 31 01:04:44 2011
     */
	public class MultiLoader
	{
		private var _numOutstanding : int;
		private var _onComplete : Function;
		private var _cache : Object = {};

		private function incrOutstanding():void {
			++_numOutstanding;
		}
		
		private function decrOutstanding():void {
			--_numOutstanding;
			checkComplete();
		}
		
		public function whenDone(onComplete : Function) : void {
			_onComplete = onComplete;
			checkComplete();
		}
		
		private function checkComplete():void {
			if ((_numOutstanding==0) && (_onComplete!=null)) {
				_onComplete();
				_onComplete = null;
			}
		}
		
		public function MultiLoader() {
			_numOutstanding = 0;
			_onComplete = null;
		}
		
		public function load(url : String, resultCallback : Function): void {
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = "text";
			var completionHandler : Function = function(event:Event):void {
				try {
					resultCallback(event.target.data);
				} catch (e : Error) {
					trace('caught error: ' + e.message);
				}
				decrOutstanding();
			}
			var errorHandler : Function = function(event:Event):void {
				decrOutstanding();
			}
			loader.addEventListener(Event.COMPLETE,                    completionHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR,             errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			incrOutstanding();
			loader.load( new URLRequest( url ) );			
		}
		
	}
}
