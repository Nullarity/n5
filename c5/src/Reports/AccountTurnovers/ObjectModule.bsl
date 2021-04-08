#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;
var AccountData;
var AccountGroup;
var LastGroup;
var ShowCurrency;
var ShowQuantity;
var DimsHierarchy;

Procedure OnCheck ( Cancel ) export
	
	getAccount ();
	if ( not checkAccount () ) then
		Cancel = true;
	endif; 
	
EndProcedure 

Procedure getAccount ()
	
	filter = DC.FindParameter ( Params.Composer, "Account" );
	AccountFilter = filter.Value;
	AccountData = GeneralAccounts.GetData ( AccountFilter );
	
EndProcedure 

Function checkAccount ()
	
	if ( ValueIsFilled ( AccountFilter ) ) then
		return true;
	endif;
	Output.FieldIsEmpty ( new Structure ( "Field", Params.Schema.Parameters.Account.Title ) );
	return false;

EndFunction 

Procedure OnCompose () export

	readParams ();
	hideParams ();
	readGroups ();
	filterByAccount ();
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
	list.Add ( "Account" );
	list.Add ( "AccountsHierarchy" );
	list.Add ( "ShowDimensions" );
	list.Add ( "DimsHierarchy" );
	list.Add ( "ShowCurrency" );
	list.Add ( "ShowQuantity" );
	
EndProcedure 

Procedure readGroups ()
	
	AccountGroup = DCsrv.GetGroup ( Params.Settings, "Account" );
	
EndProcedure

Procedure filterByAccount ()
	
	DC.SetParameter ( Params.Settings, "Account", AccountFilter );
	if ( AccountData.Fields.Main ) then
		set = Params.Schema.DataSets.DataSet.Items;
		changeQuery ( set.Balances );
		changeQuery ( set.Turnovers );
	endif; 
	
EndProcedure

Procedure changeQuery ( Source )

	Source.Query = StrReplace ( Source.Query, "Account = &Account", "Account in hierarchy ( &Account )" );

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
		LastGroup = AccountGroup;
		return;
	endif; 
	LastGroup = AccountGroup.Structure.Add ();
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
	level = Min ( p.Value, AccountData.Fields.Level );
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.DataSet.Fields;
	dims = AccountData.Dims;
	for i = 1 to level do
		LastGroup = LastGroup.Structure.Add ();
		field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
		field.Use = true;
		field.Field = new DataCompositionField ( "Dim" + i );
		field.GroupType = groupType;
		LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
		LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
		field = fields.Find ( "Dim" + i );
		field.Title = "" + dims [ i - 1 ].Presentation;
	enddo; 
	
EndProcedure

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	Reports.BalanceSheet.SetTitle ( Params, period, AccountFilter );
	
EndProcedure 

#endif