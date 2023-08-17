#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;
var AccountGroup;
var LastGroup;
var ShowCurrency;
var ShowQuantity;
var ShowRecorders;
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
	addRecorders ();
	titleReport ();
	
EndProcedure

Procedure readGroup ()
	
	AccountGroup = DCsrv.GetGroup ( Params.Settings, "Account" );
	
EndProcedure

Procedure getAccount ()
	
	AccountFilter = DC.FindValue ( Params.Settings, "Account" );
	
EndProcedure 

Procedure readParams ()
	
	settings = Params.Settings;
	p = DC.GetParameter ( settings, "ShowCurrency" );
	ShowCurrency = p.Use and p.Value;
	p = DC.GetParameter ( settings, "ShowQuantity" );
	ShowQuantity = p.Use and p.Value;
	p = DC.GetParameter ( Params.Settings, "ShowRecorders" );
	ShowRecorders = p.Use and p.Value;
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
	list.Add ( "ShowRecorders" );
	
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
	set = new Array ();
	accountDims = undefined;
	if ( AccountFilter = undefined ) then
		set = GeneralAccounts.LevelToList ( deep );
	else
		data = GeneralAccounts.GetData ( AccountFilter );
		accountDims = data.Dims;
		dims = GeneralAccounts.DimensionsByLevel ( deep, data );
		if ( dims.Count () = 0 ) then
			return;
		endif;
		for each dim in dims do
			set.Add ( dim.Position );
		enddo;
	endif;
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.DataSet1.Fields;
	for each i in set do
		LastGroup = LastGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
		field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
		field.Use = true;
		field.Field = new DataCompositionField ( "Dim" + i );
		field.GroupType = groupType;
		LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
		LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
		field = fields.Find ( "Dim" + i );
		if ( accountDims <> undefined ) then
			field.Title = "" + accountDims [ i - 1 ].Presentation;
		endif;
	enddo; 
	
EndProcedure

Procedure addRecorders ()
	
	if ( not ShowRecorders ) then
		return;
	endif; 
	recorders = DCsrv.GetGroup ( Params.Settings, "Recorder" );
	LastGroup = DCsrv.Insert ( recorders, LastGroup.Structure );
	LastGroup.Use = true;
	
EndProcedure

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	Reports.BalanceSheet.SetTitle ( Params, period );
	
EndProcedure 

#endif