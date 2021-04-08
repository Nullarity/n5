#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountGroup;
var MonthGroup;
var LastGroup;
var ShowCurrency;
var ShowQuantity;
var DimsHierarchy;

Procedure OnCompose () export

	readParams ();
	hideParams ();
	readGroups ();
	setAccountsHierarchy ();
	setResources ();
	setFilters ();
	addCurrency ();
	addDims ();
	titleReport ();
	
EndProcedure

Procedure readParams ()
	
	settings = Params.Settings;
	p = DC.GetParameter ( settings, "ShowCurrency" );
	ShowCurrency = p.Use and p.Value;
	p = DC.GetParameter ( settings, "ShowQuantity" );
	ShowQuantity = p.Use and p.Value;
	p = DC.GetParameter ( Params.Settings, "DimsHierarchy" );
	DimsHierarchy = p.Use and p.Value;
	
EndProcedure 

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	list.Add ( "AccountsHierarchy" );
	list.Add ( "ShowDimensions" );
	list.Add ( "DimsHierarchy" );
	list.Add ( "ShowCurrency" );
	list.Add ( "ShowQuantity" );
	
EndProcedure 

Procedure readGroups ()
	
	settings = Params.Settings;
	AccountGroup = DCsrv.GetGroup ( settings, "Account" );
	MonthGroup = DCsrv.GetGroup ( settings, "Month" );
	
EndProcedure

Procedure setAccountsHierarchy ()
	
	group = DCsrv.FindField ( AccountGroup, "Account" );
	p = DC.FindParameter ( Params.Settings, "AccountsHierarchy" );
	if ( p.Use
		and p.Value ) then
		group.GroupType = DataCompositionGroupType.Hierarchy;
	else
		group.GroupType = DataCompositionGroupType.Items;
	endif; 

EndProcedure

Procedure setResources ()
	
	settings = Params.Settings;
	selection = DCsrv.GetGroup ( settings, "Opening" ).Selection;
	DCsrv.GetField ( selection, "CurrencyAmountOpeningBalanceDr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "CurrencyAmountOpeningBalanceCr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "QuantityOpeningBalanceDr" ).Use = ShowQuantity;
	DCsrv.GetField ( selection, "QuantityOpeningBalanceCr" ).Use = ShowQuantity;
	selection = DCsrv.GetGroup ( settings, "Closing" ).Selection;
	DCsrv.GetField ( selection, "CurrencyAmountClosingBalanceDr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "CurrencyAmountClosingBalanceCr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "QuantityClosingBalanceDr" ).Use = ShowQuantity;
	DCsrv.GetField ( selection, "QuantityClosingBalanceCr" ).Use = ShowQuantity;
	selection = DCsrv.GetGroup ( settings, "TurnoversDr" ).Selection;
	DCsrv.GetField ( selection, "CurrencyAmountTurnoverDr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "QuantityTurnoverDr" ).Use = ShowQuantity;
	selection = DCsrv.GetGroup ( settings, "TurnoversCr" ).Selection;
	DCsrv.GetField ( selection, "CurrencyAmountTurnoverCr" ).Use = ShowCurrency;
	DCsrv.GetField ( selection, "QuantityTurnoverCr" ).Use = ShowQuantity;
	
EndProcedure

Procedure setFilters ()
	
	settings = Params.Settings;
	group = DCsrv.GetGroup ( settings, "TurnoversDr" );
	DC.FindFilter ( group, "CurrencyAmountTurnoverDr" ).Use = ShowCurrency;
	DC.FindFilter ( group, "QuantityTurnoverDr" ).Use = ShowQuantity;
	group = DCsrv.GetGroup ( settings, "TurnoversCr" );
	DC.FindFilter ( group, "CurrencyAmountTurnoverCr" ).Use = ShowCurrency;
	DC.FindFilter ( group, "QuantityTurnoverCr" ).Use = ShowQuantity;
	
EndProcedure

Procedure addCurrency ()
	
	if ( not ShowCurrency ) then
		LastGroup = MonthGroup;
		return;
	endif; 
	LastGroup = MonthGroup.Structure.Add ();
	field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
	field.Use = true;
	field.Field = new DataCompositionField ( "Currency" );
	field.GroupType = DataCompositionGroupType.Items;
	LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
	LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
	
EndProcedure

Procedure addDims ()
	
	p = DC.GetParameter ( Params.Settings, "ShowDimensions" );
	if ( p.Value = undefined
		or not p.Use ) then
		return;
	endif; 
	level = p.Value;
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.DataSet.Fields;
	for i = 1 to level do
		LastGroup = LastGroup.Structure.Add ();
		field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
		field.Use = true;
		field.Field = new DataCompositionField ( "Dim" + i );
		field.GroupType = groupType;
		LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
		LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
		field = fields.Find ( "Dim" + i );
	enddo; 
	
EndProcedure

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	Reports.BalanceSheet.SetTitle ( Params, period );
	
EndProcedure 

#endif