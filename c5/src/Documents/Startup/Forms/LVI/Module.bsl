&AtClient
var TableRow;
&AtClient
var SelectedValue;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	initSource ();
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Prices Price Amount show Object.ShowPrices;
	|VATCode VAT Total show ( Object.ShowPrices and Object.VATUse > 0 )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	Object.ShowPrices = Parameters.ShowPrices;
	
EndProcedure

&AtServer
Procedure initSource () 

	Source = new Structure ();
	Source.Insert ( "Date" );
	for each item in Metadata.Documents.Startup.Attributes do
		Source.Insert ( item.Name );
	enddo;

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure loadData ()
	
	owner = FormOwner.Object;
	Object.VATUse = owner.VATUse;
	TableRow = Object.Items.Add ();
	FillPropertyValues ( TableRow, FormOwner.Items.Items.CurrentData );
	for each item in Source do
		k = item.Key;
		Source [ k ] = owner [ k ];
	enddo;
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsLVI (), undefined );
	endif;
	
EndProcedure

&AtClient
Procedure pickValue ( Operation, Value )
	
	SelectedValue = new Structure ();
	SelectedValue.Insert ( "Operation", Operation );
	SelectedValue.Insert ( "Value", Value );
	SelectedValue.Insert ( "row", Parameters.NewRow );
	#if ( WebClient ) then
		// Bug workaround 8.3.14.1592. NotifyChoice () will not close the form.
		// Idle handler is required
		AttachIdleHandler ( "startChoosing", 0.01, true );
	#else
		NotifyChoice ( SelectedValue );
	#endif
	
EndProcedure

&AtClient
Procedure startChoosing ()
	
	NotifyChoice ( SelectedValue );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	applyCommand ( Enum.ChoiceOperationsLVI () );
	
EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	pickValue ( Command, TableRow );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsLVISaveAndNew () );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( TableRow.Prices.IsEmpty (), Source.Prices, TableRow.Prices );
	TableRow.Price = Goods.Price ( , Source.Date, prices, TableRow.Item, TableRow.Package, TableRow.Feature, , , , Source.Warehouse, Source.Currency );
	
EndProcedure 

&AtClient
Procedure FeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Source.Date );
	p.Insert ( "Company", Source.Company );
	p.Insert ( "Warehouse", Source.Warehouse );
	p.Insert ( "Currency", Source.Currency );
	p.Insert ( "Item", TableRow.Item );
	p.Insert ( "Prices", Source.Prices );
	data = getItemData ( p );
	TableRow.Package = data.Package;
	TableRow.Capacity = data.Capacity;
	TableRow.Price = data.Price;
	TableRow.Account = data.Account;
	TableRow.VATCode = data.VAT;
	TableRow.VATRate = data.Rate;
	Computations.Units ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	warehouse = Params.Warehouse;
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account" );
	data.Insert ( "Price", price );
	data.Insert ( "Account", accounts.Account );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure PackageOnChange ( Item )

	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Source.Date );
	p.Insert ( "Warehouse", Source.Warehouse );
	p.Insert ( "Currency", Source.Currency );
	p.Insert ( "Item", TableRow.Item );
	p.Insert ( "Feature", TableRow.Feature );
	p.Insert ( "Package", TableRow.Package );
	prices = ? ( TableRow.Prices.IsEmpty (), Source.Prices, TableRow.Prices );
	p.Insert ( "Prices", prices );
	data = getPackageData ( p );
	TableRow.Capacity = data.Capacity;
	TableRow.Price = data.Price;
	Computations.Units ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, , , , Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Packages ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure PriceOnChange ( Item )
	
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( TableRow );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure WarehouseOnChange ( Item )
	
	TableRow.Prices = getPrices ( TableRow.Warehouse );
	
EndProcedure

&AtServerNoContext
Function getPrices ( Warehouse ) 

	return DF.Pick ( Warehouse, "Prices" );

EndFunction

&AtClient
Procedure VATCodeOnChange ( Item )
	
	TableRow.VATRate = DF.Pick ( TableRow.VATCode, "Rate" );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( TableRow, Object.VATUse, false );
	
EndProcedure