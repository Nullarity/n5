#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Analytics;

Procedure OnCompose () export
	
	setDimensions ();
	setParams ();
	hideParams ();
	titleReport ();
	
EndProcedure

Procedure setDimensions ()
	
	Analytics = new Array ();
	settings = Params.Settings;
	level = 1;
	for i = 1 to 3 do
		p = DC.FindParameter ( settings, "DimType" + i );
		if ( not p.Use
			or not ValueIsFilled ( p.Value ) ) then
			continue;
		endif; 
		Analytics.Add ( p.Value );
		name = "Dim" + i;
		p = DC.FindParameter ( settings, name );
		if ( p.Use ) then
			DC.SetFilter ( settings, "Dim" + level, p.Value );
		endif; 
		level = level + 1;
	enddo; 
	DC.SetParameter ( settings, "DimTypes", Analytics, true );

EndProcedure 

Procedure setParams ()
	
	settings = Params.Settings;
	properties = analyticsProperties ();
	DC.SetParameter ( settings, "Currency", properties.Currency );
	DC.SetParameter ( settings, "Quantitative", properties.Quantitative );

EndProcedure 

Function analyticsProperties ()
	
	s = "
	|select isnull ( max ( Dimensions.Ref.Currency ), false ) as Currency,
	|	isnull ( max ( Dimensions.Ref.Quantitative ), false ) as Quantitative
	|from ChartOfAccounts.General.ExtDimensionTypes as Dimensions
	|";
	if ( Analytics.Count () > 0 ) then
		s = s + "
		|where Dimensions.ExtDimensionType in ( &Analytics )
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Analytics", Analytics );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction 

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	list.Add ( "DimTypes" );
	list.Add ( "DimType1" );
	list.Add ( "DimType2" );
	list.Add ( "DimType3" );
	list.Add ( "Dim1" );
	list.Add ( "Dim2" );
	list.Add ( "Dim3" );
	
EndProcedure 

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	dimension = DC.FindParameter ( Params.Settings, "Dim1" );
	if ( dimension.Use ) then
		dimension = dimension.Value;
	else
		dimension = undefined;
	endif; 
	Reports.BalanceSheet.SetTitle ( Params, period, dimension );

EndProcedure 

#endif