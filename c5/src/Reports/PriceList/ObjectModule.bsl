#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var RowsGroup;
var Removing;
var Settings;
var PricePath;

Procedure OnCheck ( Cancel ) export
	
	if ( not checkWarehouse () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkWarehouse ()
	
	group = DCsrv.GetGroup ( Params.Composer, "QuantityGroup" );
	if ( group = undefined ) then
		return true;
	endif; 
	filter = DC.FindFilter ( Params.Composer, "Quantity" );
	if ( group.Use or filter.Use ) then
		warehouse = DC.GetParameter ( Params.Composer, "Warehouse" );
		if ( not warehouse.Use ) then
			Output.PriceListWarehouseError ();
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction 

Procedure OnCompose () export
	
	Settings = Params.Settings;
	setDate ();
	setParams ();
	setPrice ();
	clean ();
	
EndProcedure

Procedure setDate ()
	
	param = DC.GetParameter ( Settings, "ReportDate" );
	if ( not param.Use or param.Value = Date ( 1, 1, 1 ) ) then
		param.Use = true;
		param.Value = CurrentDate ();
	endif; 
	
EndProcedure 

Procedure setParams ()
	
	fields = new Array ();
	fields.Add ( "Organization" );
	fields.Add ( "Warehouse" );
	for each field in fields do
		param = DC.GetParameter ( Settings, field );
		functionParam = DC.GetParameter ( Settings, field + "Param" );
		functionParam.Use = true;
		if ( param.Use ) then
			functionParam.Value = param.Value;
		endif; 
	enddo; 
	
EndProcedure 

Procedure setPrice ()
	
	PricePath = "";
	RowsGroup = DCsrv.GetGroup ( Settings, "Items" );
	Removing = new Array ();
	if ( RowsGroup = undefined ) then
		return;
	endif; 
	price = Params.Schema.CalculatedFields.Find ( "Price" );
	expression = "ServerCache.Price ( &ReportDate, Prices, Item";
	PricePath = "ServerCache.Price ( &ReportDate, Items.Prices, Items.Item";
	fields = new Array ();
	fields.Add ( "Package" );
	fields.Add ( "Feature" );
	for each fieldName in fields do
		fieldItem = DCsrv.FindField ( RowsGroup, fieldName );
		if ( fieldItem = undefined or not fieldItem.Use ) then
			expression = expression + ", ";
			PricePath = PricePath + ", ";
			Removing.Add ( fieldName );
		else
			expression = expression + ", " + fieldName;
			PricePath = PricePath + ", Items." + fieldName;
		endif; 
	enddo; 
	expression = expression + ", &OrganizationParam, &WarehouseParam )";
	PricePath = PricePath + ", &OrganizationParam, &WarehouseParam )";
	price.Expression = expression;

EndProcedure 

Procedure clean ()
	
	for each field in Removing do
		selectedField = DCsrv.GetField ( RowsGroup.Selection, field );
		if ( selectedField <> undefined ) then
			selectedField.Use = false;
		endif; 
	enddo; 
	
EndProcedure 

Procedure OnPrepare ( DataTemplate ) export
	
	setPriceFilter ( DataTemplate );
	
EndProcedure

Procedure setPriceFilter ( DataTemplate )
	
	if ( PricePath = "" ) then
		return;
	endif; 
	DataTemplate.DataSets.Items.Filter = "(" + PricePath + ") > 0";
	
EndProcedure

#endif