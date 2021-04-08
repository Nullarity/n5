&AtServer
var Copy;
&AtServer
var Env;
&AtServer
var Base;
&AtServer
var AccountData;
&AtClient
var AccountData;
&AtClient
var ChargesRow;
&AtClient
var CustomsRow;
&AtClient
var OldCustomsGroup;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Base = Parameters.Basis;
		DocumentForm.Init ( Object );
		if ( Base = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
			fillByCustoms ();
		else
			if ( TypeOf ( Base ) = Type ( "DocumentRef.VendorInvoice" ) ) then
				if ( not fillByVendorInvoice () ) then
					Cancel = true;
					return;
				endif;
			endif;	
		endif;
	endif;
	updateTotals ( ThisObject );
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsWeight", , false );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ShowDetails press Object.Detail;
	|ChargesExpenseAccount ChargesDim1 ChargesDim2 ChargesDim3 ChargesProduct ChargesProductFeature ChargesCost show Object.Detail;
	|ItemsQuantity show Object.Distribution = Enum.Distribution.Quantity;
	|ItemsWeight show Object.Distribution = Enum.Distribution.Weight
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew () 

	if ( Copy ) then
		return;
	endif;
	Object.Company = Logins.Settings ( "Company" ).Company;
	accounts = AccountsMap.Item ( Catalogs.Items.EmptyRef (), Object.Company, Catalogs.Warehouses.EmptyRef (), "VAT" );
	Object.VATAccount = accounts.VAT;

EndProcedure

&AtServer
Procedure fillByCustoms ()
	
	if ( not Copy
		and not Object.Customs.IsEmpty () ) then
		applyCustoms ();
	endif;

EndProcedure

&AtServer
Procedure applyCustoms ()
	
	customs = Object.Customs;
	company = Object.Company;
	Object.CustomsAccount = AccountsMap.Organization ( customs, company, "VendorAccount" ).VendorAccount;
	data = DF.Values ( customs, "VendorContract, VendorContract.Company as Company" );
	if ( data.Company = company ) then
		Object.Contract = data.VendorContract;
	endif; 
	
EndProcedure

#region Filling

&AtServer
Function fillByVendorInvoice () 
	
	setEnv ();
	if ( not getData () ) then
		return false;
	endif;
	headerByInvoice ();
	tablesByInvoice ();
	calcTotals ( Object );
	return true;

EndFunction

&AtServer
Procedure setEnv () 

	Env = new Structure ();
	SQL.Init ( Env );

EndProcedure

&AtServer
Function getData () 

	sqlFields ();
	getFields ();
	if ( not Env.Fields.Import ) then
		OutputCont.OnlyImportAllowed ( new Structure ( "VendorInvoice", Base ), "Import", Base );
		return false;
	endif;
	sqlItems ();
	sqlCustomGroups ();
	getTables ();
	if ( Env.CustomGroups.Count () = 0 ) then
		OutputCont.FillingDataNotFound ();
		return false;
	endif;
	return true;

EndFunction

&AtServer
Procedure sqlFields () 

	s = "
	|// @Fields
	|select Document.Company as Company, value ( Enum.Distribution.Amount ) as Distribution, Document.Import as Import
	|from Document.VendorInvoice as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure getFields ()
	
	Env.Q.SetParameter ( "Base", Base );
	SQL.Perform ( Env );
	
EndProcedure 

&AtServer
Procedure sqlItems ()
	
	s = "
	|// Items
	|select Items.CustomsGroup as CustomsGroup, Items.Invoice as Invoice, Items.Item as Item, sum ( Items.Quantity ) as Quantity, 
	|	sum ( Items.Amount ) as Amount,	sum ( Items.Weight ) as Weight
	|into Items
	|from ( 
	|	select Details.Item.CustomsGroup as CustomsGroup, Cost.Recorder as Invoice, Details.Item as Item, Cost.Quantity as Quantity, Cost.Amount as Amount, 
	|		Details.Item.Weight * Cost.Quantity as Weight
	|	from AccumulationRegister.Cost as Cost
	|		//
	|		// Details
	|		//
	|		join InformationRegister.ItemDetails as Details
	|		on Details.ItemKey = Cost.ItemKey
	|	where Cost.Recorder = &Base
	|	) as Items
	|group by Items.CustomsGroup, Items.Invoice, Items.Item
	|;
	|// #Items
	|select Items.CustomsGroup as CustomsGroup, Items.Invoice as Invoice, Items.Item as Item, Items.Quantity as Quantity, Items.Amount as Amount,
	|	Items.Weight as Weight
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlCustomGroups ()
	
	s = "
	|// CustomGroups
	|select Items.CustomsGroup as CustomsGroup, sum ( Items.Amount ) as Base
	|into CustomsGroups
	|from Items as Items
	|group by Items.CustomsGroup
	|;
	|// #CustomGroups
	|select Items.CustomsGroup as CustomsGroup, Items.Base as Base
	|from CustomsGroups as Items
	|;
	|// #Charges
	|select Items.CustomsGroup as CustomsGroup, Charges.Charge as Charge, Charges.Percent as Percent, true as Cost,
	|	case when Charges.Charge.Type = value ( Enum.CustomsCharges.VAT ) then true else false end as VAT
	|from Catalog.CustomsGroups.Charges as Charges
	|	//
	|	// CustomsGroups
	|	//
	|	join CustomsGroups as Items
	|	on Items.CustomsGroup = Charges.Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getTables ()
	
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

&AtServer
Procedure headerByInvoice () 

	fields = Env.Fields;
	Object.Company = fields.Company;
	Object.Distribution = fields.Distribution;

EndProcedure

&AtServer
Procedure tablesByInvoice () 

	customsGroups = Object.CustomsGroups;
	customsGroups.Load ( Env.CustomGroups );
	charges = Object.Charges;
	charges.Load ( Env.Charges );
	tableItems = Object.Items;
	tableItems.Load ( Env.Items );
	filter = new Structure ( "CustomsGroup" );
	for each row in customsGroups do
		filter.CustomsGroup = row.CustomsGroup;
		amount = row.Base;
		distribute ( tableItems.FindRows ( filter ), "Amount", amount );
		applyBase ( charges.FindRows ( filter ), amount );
	enddo;

EndProcedure

&AtClientAtServerNoContext
Procedure distribute ( Rows, KeyColumn, BaseAmount ) 

	divider = getTotal ( Rows, KeyColumn );
	if ( divider = 0 ) then
		return;
	endif;	
	rest = BaseAmount;
	for each row in Rows do
		row.Amount = ( row [ KeyColumn ] / divider ) * BaseAmount;
		rest = rest - row.Amount;
	enddo;
	if ( rest > 0 ) then
		row.Amount = row.Amount + rest;
	endif;

EndProcedure

&AtClientAtServerNoContext
Function getTotal ( Rows, KeyColumn )

	total = 0;
	for each row in Rows do
		total = total + row [ KeyColumn ];
	enddo;
	return total;

EndFunction

&AtClientAtServerNoContext
Procedure applyBase ( Charges, BaseAmount ) 

	for each row in Charges do
		if ( row.VAT ) then
			continue;
		endif;
		row.Amount = ( BaseAmount * row.Percent ) / 100;
	enddo;
	calcVAT ( Charges, BaseAmount );

EndProcedure

&AtClientAtServerNoContext
Procedure calcVAT ( Charges, BaseAmount ) 

	amount = 0;
	rowVAT = undefined;
	for each row in Charges do
		if ( row.VAT ) then
			row.Amount = 0;
			rowVAT = row;
		endif;
		amount = amount + row.Amount;
	enddo;
	if ( rowVAT <> undefined ) then
		rowVAT.Amount = ( ( BaseAmount + amount ) * rowVAT.Percent ) / 100;
	endif;

EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	amountVAT = 0;
	charges = Object.Charges;
	rows = charges.FindRows ( new Structure ( "VAT", true ) );
	for each row in rows do
		if ( row.Cost ) then
			amountVAT = amountVAT + row.Amount;
		endif;
	enddo;
	Object.Amount = charges.Total ( "Amount" );
	Object.VAT = amountVAT;
	
EndProcedure 

#endregion

&AtClientAtServerNoContext
Procedure updateTotals ( Form ) 

	chargesTotals = Form.ChargesTotals;
	chargesTotals.Clear ();
	table = Form.Object.Charges;
	if ( table.Count () = 0 ) then
		return;
	endif;
	filter = new Structure ( "Charge" );
	for each row in table do
		charge = row.Charge;
		filter.Charge = charge;
		if ( chargesTotals.FindRows ( filter ).Count () = 0 ) then
			amount = 0;
			for each row in table.FindRows ( filter ) do
				amount = amount + row.Amount;
			enddo;
			newRow = chargesTotals.Add ();
			newRow.Charge = charge;
			newRow.Amount = amount;
		endif;
	enddo;
	chargesTotals.Sort ( "Charge" );

EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( TypeOf ( SelectedValue ) = Type ( "DocumentRef.VendorInvoice" ) ) then 
		p = new Structure ();
		p.Insert ( "CustomsGroup", CustomsRow.CustomsGroup );
		p.Insert ( "Distribution", Object.Distribution );
		p.Insert ( "VendorInvoice", SelectedValue );
		p.Insert ( "CustomsDeclaration", Object.Ref );
		OpenForm ( "Document.CustomsDeclaration.Form.Items", p, ThisObject );
	elsif ( TypeOf ( SelectedValue ) = Type ( "Structure" ) ) then
		tableItems = Object.Items;
		if ( SelectedValue.Clear ) then
			tableItems.Clear ();
		endif;
		for each row in SelectedValue.Items do
			newRow = tableItems.Add ();
			FillPropertyValues ( newRow, row );
		enddo;
		applyAmount ();
	endif;
	
EndProcedure

&AtClient
Procedure applyAmount ()

	setBase ();
	applyBase ( chargesByCustomsGroup (), CustomsRow.Base );
	calcTotals ( Object );
	updateTotals ( ThisObject );

EndProcedure

&AtClient
Procedure setBase () 

	rows = Object.Items.FindRows ( new Structure ( "CustomsGroup", CustomsRow.CustomsGroup ) );
	CustomsRow.Base = getTotal ( rows, "Amount" );

EndProcedure

&AtClient
Function chargesByCustomsGroup () 

	return Object.Charges.FindRows ( new Structure ( "CustomsGroup", CustomsRow.CustomsGroup ) );

EndFunction

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.CustomsGroups, "CustomsGroup" );
	if ( WriteParameters.WriteMode = DocumentWriteMode.Posting ) then
		deleteUnusedRows ();
	endif;
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure deleteUnusedRows () 

	groups = new Map ();
	for each row in Object.CustomsGroups do
		groups.Insert ( row.CustomsGroup, 1 );
	enddo;
	table = Object.Items;
	for each row in getUnusedRows ( groups, table ) do
		table.Delete ( row );
	enddo;
	table = Object.Charges;
	for each row in getUnusedRows ( groups, table ) do
		table.Delete ( row );
	enddo;

EndProcedure

&AtClient
Function getUnusedRows ( Groups, Table ) 

	rows = new Array ();
	for each row in Table do
		if ( Groups.Get ( row.CustomsGroup ) = undefined ) then
			rows.Add ( row );
		endif;
	enddo;
	return rows;

EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomsOnChange ( Item )
	
	applyCustoms ();
	
EndProcedure

&AtClient
Procedure DistributionOnChange ( Item )
	
	if ( Object.Distribution.IsEmpty () ) then
		Object.Distribution = PredefinedValue ( "Enum.Distribution.Amount" );
	endif;
	Appearance.Apply ( ThisObject, "Object.Distribution" );
	
EndProcedure

// *****************************************
// *********** Table CustomGroups

&AtClient
Procedure CustomGroupsOnActivateRow ( Item )
	
	CustomsRow = Item.CurrentData;
	filterTables ();
	filterItems ();
	
EndProcedure

&AtClient
Procedure filterTables ()
	
	if ( CustomsRow = undefined ) then
		Items.Items.RowFilter = undefined;
		Items.Charges.RowFilter = undefined;
	else
		filter = new FixedStructure ( new Structure ( "CustomsGroup", CustomsRow.CustomsGroup ) );
		Items.Items.RowFilter = filter;
		Items.Charges.RowFilter = filter;
	endif;
	
EndProcedure

&AtClient
Procedure filterItems () 

	if ( customsGroupEmpty () ) then
		return;
	endif;
	groups = new Array ();
	groups.Add ( CustomsRow.CustomsGroup );
	groups.Add ( PredefinedValue ( "Catalog.CustomsGroups.EmptyRef" ) );
	list = new Array ();
	list.Add ( new ChoiceParameter ( "Filter.CustomsGroup", new FixedArray ( groups ) ) );
	list.Add ( new ChoiceParameter ( "Filter.Service", false ) );
	Items.ItemsItem.ChoiceParameters = new FixedArray ( list );

EndProcedure

&AtClient
Function customsGroupEmpty () 

	return CustomsRow = undefined or CustomsRow.CustomsGroup.IsEmpty ();

EndFunction

&AtClient
Procedure CustomGroupsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( Clone ) then
		Cancel = true;
	else
		OldCustomsGroup = undefined;
	endif;
	
EndProcedure

&AtClient
Procedure CustomGroupsBeforeDeleteRow ( Item, Cancel )
	
	deleteCustomsGroup ( CustomsRow.CustomsGroup )
	
EndProcedure

&AtClient
Procedure deleteCustomsGroup ( CustomsGroup ) 

	filter = new Structure ( "CustomsGroup", CustomsGroup );
	deleteRows ( Object.Charges, filter );
	deleteRows ( Object.Items, filter );
	calcTotals ( Object );
	updateTotals ( ThisObject );

EndProcedure

&AtClient
Procedure deleteRows ( Table, Filter ) 

	rows = Table.FindRows ( Filter );
	for each row in rows do
		Table.Delete ( row );
	enddo;

EndProcedure

&AtClient
Procedure CustomGroupsBeforeRowChange ( Item, Cancel )
	
	OldCustomsGroup = CustomsRow.CustomsGroup;
	
EndProcedure

&AtClient
Procedure CustomGroupsCustomsGroupOnChange ( Item )
	
	if ( OldCustomsGroup = CustomsRow.CustomsGroup ) then
		return;
	endif;
	if ( OldCustomsGroup <> undefined ) then
		deleteCustomsGroup ( OldCustomsGroup );
	endif;
	filter = new Structure ( "CustomsGroup", CustomsRow.CustomsGroup );
	if ( Object.CustomsGroups.FindRows ( filter ).Count () = 1 ) then
		applyCustomsGroup ();
		applyAmount ();
		updateTotals ( ThisObject );
	else
		CustomsRow.CustomsGroup = undefined;
		OutputCont.CustomsGroupAlreadyExists ( filter, Output.Row ( "CustomsGroups", CustomsRow.LineNumber, "CustomsGroup" ) );
	endif;
	filterTables ();
	filterItems ();
	
EndProcedure

&AtClient
Procedure applyCustomsGroup () 

	customsGroup = CustomsRow.CustomsGroup;
	charges = Object.Charges;
	filter = new Structure ( "CustomsGroup, Charge", customsGroup );
	table = Collections.DeserializeTable ( getCharges ( customsGroup ) );
	for each row in table do
		filter.Charge = row.Charge;
		if ( charges.FindRows ( filter ).Count () = 0 ) then
			newRow = charges.Add ();
			FillPropertyValues ( newRow, row );
			newRow.CustomsGroup = customsGroup;
			newRow.Cost = true;
		endif;
	enddo;

EndProcedure

&AtServerNoContext
Function getCharges ( val CustomsGroup ) 

	s = "
	|select Charges.Charge as Charge, Charges.Percent as Percent, 
	|	case when Charges.Charge.Type = value ( Enum.CustomsCharges.VAT ) then true else false end as VAT
	|from Catalog.CustomsGroups.Charges as Charges
	|where Charges.Ref = &CustomsGroup
	|";
	q = new Query ( s );
	q.SetParameter ( "CustomsGroup", CustomsGroup );
	return CollectionsSrv.Serialize ( q.Execute ().Unload () );

EndFunction

&AtClient
Procedure CustomGroupsBaseOnChange ( Item )
	
	applyBase (  chargesByCustomsGroup (), CustomsRow.Base );
	distributeBase ();
	calcTotals ( Object );
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure distributeBase () 

	if ( CustomsRow = undefined ) then
		return;
	endif;
	distribution = Object.Distribution;
	rows = Object.Items.FindRows ( new Structure ( "CustomsGroup", CustomsRow.CustomsGroup ) );
	baseAmount = CustomsRow.Base;
	if ( distribution = PredefinedValue ( "Enum.Distribution.Amount" ) ) then
		distribute ( rows, "Amount", baseAmount );
	elsif ( distribution = PredefinedValue ( "Enum.Distribution.Quantity" ) ) then 	
		distribute ( rows, "Quantity", baseAmount );
	elsif ( distribution = PredefinedValue ( "Enum.Distribution.Weight" ) ) then 	
		distribute ( rows, "Weight", baseAmount );
	endif;

EndProcedure

// *****************************************
// *********** Table Charges

&AtClient
Procedure ShowDetails ( Command )
	
	if ( Object.Detail
		and detailsExist () ) then
		Output.RemoveDetails ( ThisObject );
	else
		switchDetail ();
	endif;
	
EndProcedure

&AtClient
Function detailsExist ()
	
	for each row in Object.Charges do
		if ( not row.Cost ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure RemoveDetails ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	clearDetails ();
	switchDetail ();
	
EndProcedure 

&AtClient
Procedure clearDetails ()
	
	for each row in Object.Charges do
		row.ExpenseAccount = undefined;
		row.Dim1 = undefined;
		row.Dim2 = undefined;
		row.Dim3 = undefined;
		row.Product = undefined;
		row.ProductFeature = undefined;
		row.Cost = true;
	enddo; 
	
EndProcedure

&AtClient
Procedure switchDetail ()
	
	Object.Detail = not Object.Detail;
	Appearance.Apply ( ThisObject, "Object.Detail" );
	
EndProcedure 

&AtClient
Procedure ChargesBeforeRowChange ( Item, Cancel )
	
	readExpenseAccount ();
	enableDims ();
	enableExpenseAccount ();
	
EndProcedure

&AtClient
Procedure readExpenseAccount ()
	
	AccountData = GeneralAccounts.GetData ( ChargesRow.ExpenseAccount );
	
EndProcedure 

&AtClient
Procedure enableDims ()
	
	level = AccountData.Fields.Level;
	for i = 1 to 3 do
		disable = ( level < i );
		Items [ "ChargesDim" + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure

&AtClient
Procedure enableExpenseAccount () 

	if ( ChargesRow = undefined ) then
		return;
	endif;
	Items.ChargesExpenseAccount.ReadOnly = ChargesRow.Cost;

EndProcedure

&AtClient
Procedure ChargesOnActivateRow ( Item )
	
	ChargesRow = Item.CurrentData;
	enableExpenseAccount ();
	
EndProcedure

&AtClient
Procedure ChargesOnEditEnd ( Item, NewRow, CancelEdit )
	
	resetAnalytics ();
	calcTotals ( Object );
    updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure resetAnalytics ()
	
	Items.ChargesDim1.ReadOnly = false;
	Items.ChargesDim2.ReadOnly = false;
	Items.ChargesDim3.ReadOnly = false;
	
EndProcedure 

&AtClient
Procedure ChargesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( customsGroupEmpty () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtClient
Procedure ChargesOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		ChargesRow.CustomsGroup = CustomsRow.CustomsGroup;
		ChargesRow.Cost = true;
	endif;
	
EndProcedure

&AtClient
Procedure ChargesAfterDeleteRow ( Item )
	
	calcTotals ( Object );
    updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChargesExpenseAccountOnChange ( Item )
	
	readExpenseAccount ();
	adjustDims ();
	enableDims ();
	
EndProcedure

&AtClient
Procedure adjustDims ()
	
	fields = AccountData.Fields;
	dims = AccountData.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		ChargesRow.Dim1 = null;
		ChargesRow.Dim2 = null;
		ChargesRow.Dim3 = null;
	elsif ( level = 1 ) then
		ChargesRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( ChargesRow.Dim1 );
		ChargesRow.Dim2 = null;
		ChargesRow.Dim3 = null;
	elsif ( level = 2 ) then
		ChargesRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( ChargesRow.Dim1 );
		ChargesRow.Dim2 = dims [ 1 ].ValueType.AdjustValue ( ChargesRow.Dim2 );
		ChargesRow.Dim3 = null;
	else
		ChargesRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( ChargesRow.Dim1 );
		ChargesRow.Dim2 = dims [ 1 ].ValueType.AdjustValue ( ChargesRow.Dim2 );
		ChargesRow.Dim3 = dims [ 2 ].ValueType.AdjustValue ( ChargesRow.Dim3 );
	endif; 

EndProcedure 

&AtClient
Procedure ChargesDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseDim ( Item, Level, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Object.Company;
	p.Level = Level;
	p.Dim1 = ChargesRow.Dim1;
	p.Dim2 = ChargesRow.Dim2;
	p.Dim3 = ChargesRow.Dim3;
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

&AtClient
Procedure ChargesDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ChargesDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ChargesPercentOnChange ( Item )
	
	applyPercent ();
	
EndProcedure

&AtClient
Procedure applyPercent () 

	if ( not ChargesRow.VAT ) then
		ChargesRow.Amount = ( CustomsRow.Base * ChargesRow.Percent ) / 100;
	endif;
	calcVAT ( chargesByCustomsGroup (), CustomsRow.Base );
	calcTotals ( Object );

EndProcedure

&AtClient
Procedure ChargesChargeOnChange ( Item )
	
	charge = ChargesRow.Charge;
	filter = new Structure ( "CustomsGroup, Charge", ChargesRow.CustomsGroup, charge );
	if ( Object.Charges.FindRows ( filter ).Count () > 1 ) then
		ChargesRow.Charge = undefined;
		OutputCont.ChargeAlreadyExist ( filter, Output.Row ( "Charges", ChargesRow.LineNumber, "Charge" ) );
		return;
	endif;
	ChargesRow.VAT = ( DF.Pick ( charge, "Type" ) = PredefinedValue ( "Enum.CustomsCharges.VAT" ) );
	
EndProcedure

&AtClient
Procedure ChargesCostOnChange ( Item )
	
	if ( ChargesRow.Cost ) then
		ChargesRow.ExpenseAccount = undefined;
	endif;
	enableExpenseAccount ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure AddFromInvoice ( Command )
	
	if ( customsGroupEmpty () ) then
		return;
	endif;
	filter = new Structure ( "Import, Posted", true, true );
	p = new Structure ( "Filter", filter );
	OpenForm ( "Document.VendorInvoice.ChoiceForm", p, ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	applyAmount ();
	
EndProcedure

&AtClient
Procedure ItemsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		Item.CurrentData.CustomsGroup = CustomsRow.CustomsGroup;
	endif;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	applyAmount ();
	
EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	applyAmount ();
		
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "ItemsInvoice" ) then
		value = Item.CurrentData.Invoice;
		if ( ValueIsFilled ( value ) ) then
			StandardProcessing = false;
			ShowValue ( , value );
		endif; 
	endif;
	
EndProcedure
