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

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setID ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure setID ()
	
	LastID = -1; 
	for each row in Object.CustomsGroups do
		if ( row.ID > LastID ) then
			LastID = row.ID;
		endif;
	enddo;
	LastID = LastID + 1;

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
		setID ();
		Constraints.ShowAccess ( ThisObject );
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
		Output.OnlyImportAllowed ( new Structure ( "VendorInvoice", Base ), "Import", Base );
		return false;
	endif;
	sqlItems ();
	sqlCustomGroups ();
	getTables ();
	if ( Env.CustomGroups.Count () = 0 ) then
		Output.FillingDataWasNotFound ();
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
	|// Groups ID
	|select distinct recordautonumber () as ID, Items.CustomsGroup as CustomsGroup
	|into Groups
	|from Items
	|;
	|// #Items
	|select Items.Invoice as Invoice, Items.Item as Item, Items.Quantity as Quantity, Items.Amount as Amount,
	|	Items.Weight as Weight, Groups.ID as ID
	|from Items as Items
	|	//
	|	// Groups ID
	|	//
	|	join Groups as Groups
	|	on Groups.CustomsGroup = Items.CustomsGroup
	|	//
	|	// Rows
	|	//
	|	join (
	|		select min ( Items.LineNumber ) as Row, Items.Item as Item
	|		from Document.VendorInvoice.Items as Items
	|		where Items.Ref = &Base
	|		group by Items.Item
	|	) as Rows
	|	on Rows.Item = Items.Item
	|order by Rows.Row
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlCustomGroups ()
	
	s = "
	|// CustomGroups
	|select Items.CustomsGroup as CustomsGroup, sum ( Items.Amount ) as Base,
	|	Groups.ID as ID
	|into CustomsGroups
	|from Items as Items
	|	//
	|	// Groups ID
	|	//
	|	join Groups as Groups
	|	on Groups.CustomsGroup = Items.CustomsGroup
	|group by Items.CustomsGroup, Groups.ID
	|;
	|// #CustomGroups
	|select Groups.ID as ID, Groups.CustomsGroup as CustomsGroup, Groups.Base as Base
	|from CustomsGroups as Groups
	|;
	|// #Charges
	|select Groups.ID as ID, Charges.Charge as Charge, Charges.Percent as Percent, true as Cost,
	|	case when Charges.Charge.Type = value ( Enum.CustomsCharges.VAT ) then true else false end as VAT
	|from Catalog.CustomsGroups.Charges as Charges
	|	//
	|	// CustomsGroups
	|	//
	|	join CustomsGroups as Groups
	|	on Groups.CustomsGroup = Charges.Ref
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
	filter = new Structure ( "ID" );
	for each row in customsGroups do
		filter.ID = row.ID;
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
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

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
		groups.Insert ( row.ID, 1 );
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
		if ( Groups.Get ( row.ID ) = undefined ) then
			rows.Add ( row );
		endif;
	enddo;
	return rows;

EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

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
	
EndProcedure

&AtClient
Procedure filterTables ()
	
	if ( CustomsRow = undefined ) then
		Items.Items.RowFilter = undefined;
		Items.Charges.RowFilter = undefined;
	else
		filter = new FixedStructure ( new Structure ( "ID", CustomsRow.ID ) );
		Items.Items.RowFilter = filter;
		Items.Charges.RowFilter = filter;
	endif;
	
EndProcedure

&AtClient
Procedure CustomGroupsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		newCustomsGroup ();
	endif;
	
EndProcedure

&AtClient
Procedure newCustomsGroup ()
	
	LastID = LastID + 1;
	Items.CustomGroups.CurrentData.ID = LastID;

EndProcedure

&AtClient
Procedure CustomGroupsBeforeDeleteRow ( Item, Cancel )
	
	deleteID ( CustomsRow.ID )
	
EndProcedure

&AtClient
Procedure deleteID ( ID ) 

	filter = new Structure ( "ID", ID );
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
Procedure CustomGroupsCustomsGroupOnChange ( Item )
	
	applyCustomsGroup ();
	applyAmount ();
	updateTotals ( ThisObject );
	filterTables ();
	
EndProcedure

&AtClient
Procedure applyCustomsGroup () 

	id = CustomsRow.ID;
	charges = Object.Charges;
	filter = new Structure ( "ID, Charge", id );
	table = Collections.DeserializeTable ( getCharges ( CustomsRow.CustomsGroup ) );
	for each row in table do
		filter.Charge = row.Charge;
		if ( charges.FindRows ( filter ).Count () = 0 ) then
			newRow = charges.Add ();
			FillPropertyValues ( newRow, row );
			newRow.ID = id;
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
	
	applyBase (  chargesByID (), CustomsRow.Base );
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
	rows = Object.Items.FindRows ( new Structure ( "ID", CustomsRow.ID ) );
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
	setFilter ();
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
Procedure setFilter ( Level = 1 )
	
	table = Items.Charges;
	path = table.Name + "Dim";
	for i = Level to 3 do
		filter = new Array ();
		control = Items [ path + i ];
		owner = fetchOwner ( table, i );
		oldOwners = control.ChoiceParameters;
		if ( oldOwners.Count () = 0 ) then
			previousOwner = undefined;
		else
			previousOwner = null;
			ownerType = TypeOf ( owner );
			for each parameter in oldOwners do
				parameterValue = parameter.Value;
				if ( parameter.Name = "Filter.Owner"
					and TypeOf ( parameterValue ) = ownerType
					and parameterValue = owner ) then
					previousOwner = owner;
					break;
				endif;
			enddo;
		endif;
		if ( previousOwner <> owner ) then
			table.CurrentData [ "Dim" + i ] = undefined;
		endif;
		if ( owner <> undefined ) then
			filter.Add ( new ChoiceParameter ( "Filter.Owner", owner ) );
		endif;
		control.ChoiceParameters = new FixedArray ( filter );
	enddo;

EndProcedure

&AtClient
Function fetchOwner ( Table, Level )

	if ( Level > AccountData.Fields.Level ) then
		return undefined;
	endif;
	levelIndex = Level - 1;
	dims = AccountData.Dims;
	owners = dims [ levelIndex ].Owners;
	company = Type ( "CatalogRef.Companies" );
	parentIndex = levelIndex - 1;
	for each owner in owners do
		j = parentIndex;
		while ( j >= 0 ) do
			parentTypes = dims [ j ].ValueType;
			if ( parentTypes.ContainsType ( owner ) ) then
				return Table.CurrentData [ "Dim" + ( j + 1 ) ];
			endif;
			j = j - 1;
		enddo;
		if ( owner = company ) then
			return Object.Company;
		endif;
	enddo;

EndFunction

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
Procedure ChargesOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		ChargesRow.ID = CustomsRow.ID;
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
	setFilter ();
	
EndProcedure

&AtClient
Procedure adjustDims ()
	
	dims = AccountData.Dims;
	top = AccountData.Fields.Level;
	for i = 1 to 3 do
		name = "Dim" + i;
		ChargesRow [ name ] = ? ( i > top, null, dims [ i - 1 ].ValueType.AdjustValue ( ChargesRow [ name ] ) );
	enddo;

EndProcedure 

&AtClient
Procedure ChargesDimOnChange ( Item )
	
	setFilter ( 1 + Right ( Item.Name, 1 ) );
	
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
	calcVAT ( chargesByID (), CustomsRow.Base );
	calcTotals ( Object );

EndProcedure

&AtClient
Procedure ChargesChargeOnChange ( Item )
	
	charge = ChargesRow.Charge;
	filter = new Structure ( "ID, Charge", ChargesRow.ID, charge );
	if ( Object.Charges.FindRows ( filter ).Count () > 1 ) then
		ChargesRow.Charge = undefined;
		Output.ChargeAlreadyExist ( filter, Output.Row ( "Charges", ChargesRow.LineNumber, "Charge" ) );
	else
		ChargesRow.VAT = ( DF.Pick ( charge, "Type" ) = PredefinedValue ( "Enum.CustomsCharges.VAT" ) );
	endif;
	
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
	
	filter = new Structure ( "Import, Posted", true, true );
	p = new Structure ( "Filter", filter );
	OpenForm ( "Document.VendorInvoice.ChoiceForm", p, Items.Items );
	
EndProcedure

&AtClient
Procedure ItemsChoiceProcessing ( Item, ValueSelected, StandardProcessing)

	type = TypeOf ( ValueSelected );
	if ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		selectItems ( ValueSelected ); 
	elsif ( type = Type ( "Structure" ) ) then
		applyItems ( ValueSelected );
	endif;

EndProcedure

&AtClient
Procedure selectItems ( Invoice )
	
	p = new Structure ();
	p.Insert ( "ID", CustomsRow.ID );
	p.Insert ( "Distribution", Object.Distribution );
	p.Insert ( "VendorInvoice", Invoice );
	p.Insert ( "CustomsDeclaration", Object.Ref );
	p.Insert ( "AlreadySelected", alreadySelected ( Invoice ) );
	OpenForm ( "Document.CustomsDeclaration.Form.Items", p, Items.Items );

EndProcedure

&AtClient
Function alreadySelected ( Invoice )
	
	list = new Array ();
	for each row in Object.Items.FindRows ( new Structure ( "Invoice", Invoice ) ) do
		list.Add ( row.Item );
	enddo;
	return new FixedArray ( list );

EndFunction

&AtClient
Procedure applyItems ( Data )
	
	table = Object.Items;
	if ( Data.Clear ) then
		table.Clear ();
	endif;
	id = CustomsRow.ID;
	for each row in Data.Items do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		newRow.ID = id;
	enddo;
	applyAmount ();

EndProcedure

&AtClient
Procedure applyAmount ()

	setBase ();
	applyBase ( chargesByID (), CustomsRow.Base );
	calcTotals ( Object );
	updateTotals ( ThisObject );

EndProcedure

&AtClient
Procedure setBase () 

	rows = Object.Items.FindRows ( new Structure ( "ID", CustomsRow.ID ) );
	CustomsRow.Base = getTotal ( rows, "Amount" );

EndProcedure

&AtClient
Function chargesByID () 

	return Object.Charges.FindRows ( new Structure ( "ID", CustomsRow.ID ) );

EndFunction

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	applyAmount ();
	
EndProcedure

&AtClient
Procedure ItemsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		Item.CurrentData.ID = CustomsRow.ID;
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
