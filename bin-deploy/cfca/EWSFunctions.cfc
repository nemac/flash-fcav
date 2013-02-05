<cfcomponent output="false" >
	
	<cffunction name="getWMSTitleForLayer" access="remote" returntype="string">
		<cfargument name="theURL" type="String" required="true">
		<cfargument name="layerName" type="String" required="true">
		
		<!--- get capabilities statement for WMS and convert to XML --->
		<cfhttp url = "#theURL#" method = "get" timeout="60">
		<cfset MyXml = XmlParse(#cfhttp.fileContent#)>
		
		<!--- search for all Layers nodes using local namespace --->
		<cfset arrayLayers = XmlSearch(MyXml, "//*[local-name()='Layer']")>
		
		<!--- loop over them and see if layer name is passed name --->
		<cfloop index="i" from="1" to="#ArrayLen(arrayLayers)#">
			<cfset thisLayerInfoNodes = arrayLayers[i].XmlChildren>
			<cfset thisLayerName = "">
			<cfset thisLayerTitle = "">
		
			<cfloop index="j" from="1" to="#ArrayLen(thisLayerInfoNodes)#">
				<cfif thisLayerInfoNodes[j].XmlName EQ "Name">
					<cfset thisLayerName = thisLayerInfoNodes[j].XmlText>
				</cfif>
				<cfif thisLayerInfoNodes[j].XmlName EQ "Title">
					<cfset thisLayerTitle = thisLayerInfoNodes[j].XmlText>
				</cfif>
			</cfloop>
			<cfif thisLayerName EQ #layerName#> <!--- return the title --->
				<cfreturn #thisLayerTitle#>
			</cfif>
		</cfloop>
		
		<!--- return layer name if layer not found or no title --->
		<cfreturn #layerName#>	

	</cffunction>
		
</cfcomponent>

