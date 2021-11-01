#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;
var AccountGroup;
var LastGroup;
var ShowCurrency;
var ShowQuantity;
var DimsHierarchy;

Procedure OnCompose () export
	
	readGroup ();
	if ( AccountGroup = undefined ) then
		return;
	endif; 
	getAccount ();
	readParams ();
	hideParams ();
	setAccountsHierarchy ();
	setResources ();
	addCurrency ();
	addDims ();
	titleReport ();
	
EndProcedure

Procedure readGroup ()
	
	AccountGroup = DCsrv.GetGroup ( Params.Settings, "Account" );
	
EndProcedure

Procedure getAccount ()
	
	filter = DC.FindFilter ( Params.Settings, "Account" );
	account = filter.RightValue;
	if ( filter.Use
		and filter.ComparisonType = DataCompositionComparisonType.Equal
		and not account.IsEmpty () ) then
		AccountFilter = account;
	endif;
	
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

Procedure setAccountsHierarchy ()
	
	group = DCsrv.FindField ( AccountGroup, "Account" );
	p = DC.FindParameter ( Params.Settings, "AccountsHierarchy" );
	group.GroupType = ? ( p.Value, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );

EndProcedure

Procedure setResources ()
	
	fields = new Array ();
	fields.Add ( "CurrencyAmountOpeningBalanceDr" );
	fields.Add ( "CurrencyAmountOpeningBalanceCr" );
	fields.Add ( "CurrencyAmountTurnoverDr" );
	fields.Add ( "CurrencyAmountTurnoverCr" );
	fields.Add ( "CurrencyAmountClosingBalanceDr" );
	fields.Add ( "CurrencyAmountClosingBalanceCr" );
	setUsage ( fields, ShowCurrency );
	fields.Clear ();
	fields.Add ( "QuantityOpeningBalanceDr" );
	fields.Add ( "QuantityOpeningBalanceCr" );
	fields.Add ( "QuantityClosingBalanceDr" );
	fields.Add ( "QuantityClosingBalanceCr" );
	fields.Add ( "QuantityTurnoverDr" );
	fields.Add ( "QuantityTurnoverCr" );
	setUsage ( fields, ShowQuantity );
	
EndProcedure

Procedure setUsage ( Fields, Flag )
	
	selection = Params.Settings.Selection;
	for each field in fields do
		item = DCsrv.GetField ( selection, field );
		if ( item <> undefined ) then
			item.Use = Flag;
		endif; 
	enddo; 
	
EndProcedure 

Procedure addCurrency ()
	
	if ( not ShowCurrency ) then
		LastGroup = AccountGroup;
		return;
	endif; 
	LastGroup = AccountGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
	field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
	field.Use = true;
	field.Field = new DataCompositionField ( "Currency" );
	field.GroupType = DataCompositionGroupType.Items;
	LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
	LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
	
EndProcedure 

Procedure addDims ()
	
	p = DC.GetParameter ( Params.Settings, "ShowDimensions" );
	deep = p.Value;
	if ( not ( p.Use and ValueIsFilled ( deep ) ) ) then
		return;
	endif;
	if ( AccountFilter = undefined ) then
		level = GeneralAccounts.LevelDeep ( deep );
	else
		data = GeneralAccounts.GetData ( AccountFilter );
		dims = GeneralAccounts.DimensionsByLevel ( deep, data );
		level = dims.Count ();
		if ( level = 0 ) then
			return;
		endif;
		DC.SetParameter ( Params.Settings, "Dims", dims );
	endif;
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.DataSet1.Fields;
	for i = 1 to level do
		LastGroup = LastGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
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