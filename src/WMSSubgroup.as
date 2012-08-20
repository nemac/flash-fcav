package
{
	public class WMSSubgroup
	{
        public var label:String       = null;
        public var id:int             = -1;
        public var layers:Array       = null;
		public var layerCounter:int   = -1;

		public function WMSSubgroup() {
			this.layers = new Array();
		}
	}
}
