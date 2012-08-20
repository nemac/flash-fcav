// ActionScript file
 import com.esri.ags.FeatureSet;
 import com.esri.ags.Graphic;
 import com.esri.ags.SpatialReference;
 import com.esri.ags.events.DrawEvent;
 import com.esri.ags.events.ExtentEvent;
 import com.esri.ags.events.GeometryServiceEvent;
 import com.esri.ags.events.LayerEvent;
 import com.esri.ags.events.MapMouseEvent;
 import com.esri.ags.geometry.Extent;
 import com.esri.ags.geometry.Geometry;
 import com.esri.ags.geometry.MapPoint;
 import com.esri.ags.geometry.Polygon;
 import com.esri.ags.geometry.Polyline;
 import com.esri.ags.symbols.SimpleMarkerSymbol;
 import com.esri.ags.layers.ArcGISDynamicMapServiceLayer;
 import com.esri.ags.layers.ArcGISImageServiceLayer;
 import com.esri.ags.layers.GraphicsLayer;
 import com.esri.ags.layers.supportClasses.LayerInfo;
 import com.esri.ags.layers.supportClasses.TimeInfo;
 import com.esri.ags.tasks.GeometryService;
 import com.esri.ags.tasks.IdentifyTask;
 import com.esri.ags.tasks.ImageServiceIdentifyTask;
 import com.esri.ags.tasks.supportClasses.BufferParameters;
 import com.esri.ags.tasks.supportClasses.IdentifyParameters;
 import com.esri.ags.tasks.supportClasses.IdentifyResult;
 import com.esri.ags.tasks.supportClasses.ImageServiceIdentifyParameters;
 import com.esri.ags.tasks.supportClasses.ImageServiceIdentifyResult;
 import com.esri.ags.tasks.supportClasses.Query;
 import com.esri.ags.tasks.QueryTask;
 import com.esri.ags.tools.NavigationTool;  
 import com.esri.ags.utils.WebMercatorUtil;

 import com.abdulqabiz.utils.QueryString

 import flash.events.Event;
 import flash.events.MouseEvent;
 import flash.geom.Point;
 import flash.geom.Rectangle;
 import flash.net.URLLoader;
 import flash.net.URLRequest;
 import flash.utils.ByteArray;
 import flash.xml.XMLNode;
 
 import mx.containers.Accordion;
 import mx.containers.Canvas;
 import mx.collections.ArrayCollection;
 import mx.containers.TabNavigator;
 import mx.controls.Alert;
 import mx.controls.DataGrid;
 import mx.controls.dataGridClasses.DataGridColumn;
 import mx.controls.Label;
 import mx.controls.Menu;
 import mx.controls.RadioButton;
 import mx.controls.Text;
 import mx.controls.TextArea;
 import mx.controls.TextInput;
 import mx.core.FlexGlobals;
 import mx.core.ScrollPolicy;
 import mx.core.UIComponent;
 import mx.events.ItemClickEvent;
 import mx.events.ListEvent;
 import mx.events.ResizeEvent;
 import mx.graphics.codec.PNGEncoder;
 import mx.managers.CursorManager;
 import mx.managers.PopUpManager;
 import mx.rpc.AsyncResponder;
 import mx.rpc.events.ResultEvent;
 import mx.rpc.events.FaultEvent;
 import mx.rpc.Fault; 
 import mx.rpc.soap.WebService;
 import mx.utils.ObjectProxy;  
 
 import multigraph.ClosableTitleWindow;
 import multigraph.Multigraph;

 import edu.unca.nemac.gisviewer.LayerPropertiesDialog;
 import edu.unca.nemac.gisviewer.LayerTOC;
 import edu.unca.nemac.gisviewer.MultiLoader;
 import edu.unca.nemac.gisviewer.SuperPanel;
 import edu.unca.nemac.gisviewer.WMSMapServiceLayer;
 import edu.unca.nemac.gisviewer.WMSTiledMapServiceLayer;
 
 import memorphic.xpath.XPathQuery;

 import org.alivepdf.colors.RGBColor;
 import org.alivepdf.display.Display;
 import org.alivepdf.layout.Layout;
 import org.alivepdf.layout.Orientation;
 import org.alivepdf.layout.Size;
 import org.alivepdf.layout.Unit;
 import org.alivepdf.pdf.PDF;
 import org.alivepdf.saving.Download;
 import org.alivepdf.saving.Method;
 
 import spark.events.IndexChangeEvent;

