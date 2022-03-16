&AtServer
var Env;
&AtServer
var Base;
&AtServer
var LVIInventoryExists;
&AtClient
var ItemsRow;
&AtServer
var AccountData;
&AtClient
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	readAccount ();
	labelDims ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.ExpenseAccount );
	ExpensesLevel = AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ()
	
	i = 1;
	for each dim in AccountData.Dims do
		Items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			fillNew ();
		else
			if ( TypeOf ( Base ) = Type ( "DocumentRef.LVIInventory" ) ) then
				fillByLVIInventory ();
			endif;
			setCurrency ();
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	setLinks ();
	setAccounts ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ItemsShowDetails press Object.Detail;
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|Prices Amount VATUse show Object.ShowPrices;
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2;
	|Links show ShowLinks;
	|VAT show ( Object.ShowPrices and Object.VATUse > 0 );
	|ItemsDim1 ItemsDim2 ItemsDim3 ItemsProduct ItemsProductFeature ItemsExpenseAccount show Object.Detail;
	|ItemsAmount ItemsPrice ItemsPrices show Object.ShowPrices;
	|ItemsVATCode ItemsVAT ItemsTotal show ( Object.ShowPrices and Object.VATUse > 0 )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	Object.Company = Logins.Settings ( "Company" ).Company;
	Object.Prices = DF.Pick ( Object.Company, "CostPrices" );
	setCurrency ();
	
EndProcedure 

&AtServer
Procedure fillByLVIInventory ()
	
	setEnv ();
	sqlLVIInventory ();
	SQL.Perform ( Env );
	headerByLVIInventory ();
	itemsByLVIInventory ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlLVIInventory ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Department as Department
	|from Document.LVIInventory as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Capacity as Capacity, Items.Series as Series,
	|	Items.Package as Package, Items.Account as Account, ( - Items.QuantityDifference ) as Quantity, 
	|	( - Items.QuantityPkgDifference ) as QuantityPkg 
	|from Document.LVIInventory.Items as Items
	|where Items.Ref = &Base 
	|	and Items.QuantityDifference < 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByLVIInventory ()
	
	FillPropertyValues ( Object, Env.Fields );
	Object.LVIInventory = Base;
	
EndProcedure 

&AtServer
Procedure itemsByLVIInventory ()
	
	table = Env.Items;
	if ( table.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	Object.Items.Load ( table );
	
EndProcedure

&AtServer
Procedure setCurrency ()
	
	Object.Currency = Application.Currency ();
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	rates = CurrenciesSrv.Get ( Object.Currency );
	Object.Rate = rates.Rate;
	Object.Factor = rates.Factor;
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantity, ItemsTotalQuantityPkg", false );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "LVIInventory", Object.LVIInventory );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;

EndProcedure 

&AtServer
Procedure setAccounts ()
	
	table = getSettings ();
	amortizationAccount = ChartsOfCharacteristicTypes.Settings.LVIAmortizationAccount;
	for each row in table do
		value = row.Value;
		if ( row.Parameter = amortizationAccount ) then 
			Object.AmortizationAccount = value;
		else
			Account = value;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getSettings ()
	
	accounts = new Array ();
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.LVIAmortizationAccount )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.LVIExploitationAccount )" );
	s = "
	|select Settings.Parameter as Parameter, Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter in ( " + StrConcat ( accounts, "," ) + ") ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure sqlLinks ()
	
	LVIInventoryExists = not Object.LVIInventory.IsEmpty ();
	if ( LVIInventoryExists ) then
		s = "
		|// #LVIInventory
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.LVIInventory as Documents
		|where Documents.Ref = &LVIInventory
		|";
		Env.Selection.Add ( s );
	endif;
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( LVIInventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.LVIInventory, Metadata.Documents.LVIInventory ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
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
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	Object.VAT = items.Total ( "VAT" );
	Object.Amount = items.Total ( "Total" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , , currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ShowPrices" );
	
EndProcedure

&AtClient
Procedure ExpenseAccountOnChange ( Item )
	
	applyExpenseAccount ();
	
EndProcedure

&AtServer
Procedure applyExpenseAccount ()
	
	readAccount ();
	adjustDims ( AccountData, Object );
	labelDims ();
	setDepartment ( Object, Object );
	Appearance.Apply ( ThisObject, "ExpensesLevel" );
	      	
EndProcedure 

&AtClientAtServerNoContext
Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure 

&AtClientAtServerNoContext
Procedure setDepartment ( Object, Target ) 

	department = Object.Department;
	if ( department.IsEmpty () ) then
		return;
	endif;
	typeDepartments = Type ( "CatalogRef.Departments" );
	if ( TypeOf ( Target.Dim1 ) = typeDepartments ) then
		Target.Dim1 = department;
	elsif ( TypeOf ( Target.Dim2 ) = typeDepartments ) then
		Target.Dim2 = department;
	elsif ( TypeOf ( Target.Dim3 ) = typeDepartments ) then
		Target.Dim3 = department;
	endif;

EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
EndProcedure

&AtClient
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

// *****************************************
// *********** Table Items

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
	
	for each row in Object.Items do
		if ( not row.ExpenseAccount.IsEmpty () ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure switchDetail ()
	
	Object.Detail = not Object.Detail;
	Appearance.Apply ( ThisObject, "Object.Detail" );
	
EndProcedure 

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
	
	for each row in Object.Items do
		row.ExpenseAccount = undefined;
		row.Dim1 = undefined;
		row.Dim2 = undefined;
		row.Dim3 = undefined;
		row.Product = undefined;
		row.ProductFeature = undefined;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	readTableAccount ();
	enableDims ();
	
EndProcedure

&AtClient
Procedure readTableAccount ()
	
	AccountData = GeneralAccounts.GetData ( ItemsRow.ExpenseAccount );
	
EndProcedure 

&AtClient
Procedure enableDims ()
	
	fields = AccountData.Fields;
	level = fields.Level;
	for i = 1 to 3 do
		disable = ( level < i );
		Items [ "ItemsDim" + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	resetAnalytics ();
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure resetAnalytics ()
	
	Items.ItemsDim1.ReadOnly = false;
	Items.ItemsDim2.ReadOnly = false;
	Items.ItemsDim3.ReadOnly = false;
	
EndProcedure 

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.Account = Account;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , , Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, , , , , Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, , , , , Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsExpenseAccountOnChange ( Item )
	
	readTableAccount ();
	adjustDims ( AccountData, ItemsRow );
	enableDims ();
	setDepartment ( Object, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseDim ( Item, Level, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Object.Company;
	p.Level = Level;
	p.Dim1 = ItemsRow.Dim1;
	p.Dim2 = ItemsRow.Dim2;
	p.Dim3 = ItemsRow.Dim3;
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

&AtClient
Procedure ItemsDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse, false );
	
EndProcedure

// *****************************************
// *********** Group Stakeholders

&AtClient
Procedure ApprovedOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Approved, Object.ApprovedPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure HeadOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Head, Object.HeadPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure MembersMemberOnChange ( Item )
	
	MembersForm.FillPosition ( Items.Members.CurrentData, Object.Date );
	
EndProcedure