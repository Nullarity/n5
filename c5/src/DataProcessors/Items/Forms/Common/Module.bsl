// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setCurrentItem ();
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg, QuantityAvailable", false );
	Options.Company ( ThisObject, Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Package QuantityPkg show not Service;
	|Description show Service;
	|DiscountRate Discount show Discounts and ShowPrice;
	|DeliveryDate show Delivery;
	|Price Amount Prices show ShowPrice;
	|VATCode VAT show ( ShowPrice and VATUse > 0 );
	|Total show ( ShowPrice and VATUse = 2 );
	|Series show SeriesControl;
	|ProducerPrice show
	|( ShowPrice
	|	and Social
	|	and ShowSocial );
	|ExtraCharge show
	|( ShowPrice
	|	and Social
	|	and ShowExtraCharge );
	|Warning show Leaving and ( ( QuantityAvailable < Quantity and not CountPackages )
	|	or ( QuantityAvailable < QuantityPkg and CountPackages ) )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	TableRow = Parameters.TableRow;
	FillPropertyValues ( ThisObject, TableRow );
	Source = Parameters.Source;
	QuantityAvailable = Parameters.QuantityAvailable;
	CountPackages = Parameters.CountPackages;
	Discounts = Parameters.Discounts;
	Delivery = Parameters.Delivery;
	Service = Parameters.Service;
	Organization = Parameters.Organization;
	Contract = Parameters.Contract;
	VendorContract = Parameters.VendorContract;
	Product = TableRow.Item;
	Company = Source.Company;
	ShowPrice = Source.ShowPrice;
	if ( ShowPrice ) then
		Prices = Source.Prices;
	endif;
	VATUse = Source.VATUse;
	type = Source.Type;
	if not ( type.Assembling
		or type.Disassembling
		or type.Production
		or type.TimeEntry ) then
		VATCode = TableRow.VATCode;
		VATRate = TableRow.VATRate;
		VAT = TableRow.VAT;
		Total = TableRow.Total;
	endif;
	Leaving = type.Sale
		or type.Invoice
		or type.Assembling
		or type.Disassembling;
	ShowExtraCharge = Parameters.ShowExtraCharge;
	ShowSocial = Parameters.ShowSocial;
	SeriesControl = Parameters.SeriesControl;
	
EndProcedure

&AtServer
Procedure setCurrentItem ()
	
	if ( Service
		or not Options.Packages () ) then
		CurrentItem = Items.Quantity;
	else
		CurrentItem = Items.QuantityPkg;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	NotifyChoice ( getData () );
	
EndProcedure

&AtClient
Function getData ()
	
	FillPropertyValues ( TableRow, ThisObject );
	rows = new Array ();
	rows.Add ( TableRow );
	return rows;
	
EndFunction

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	updateWarning ();
	
EndProcedure

&AtClient
Procedure updateWarning ()
	
	Appearance.Apply ( ThisObject, "Quantity" );

EndProcedure

&AtClient
Procedure PackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Source.Date );
	p.Insert ( "Organization", Organization );
	p.Insert ( "Contract", Contract );
	p.Insert ( "VendorContract", VendorContract );
	p.Insert ( "Warehouse", Source.Warehouse );
	p.Insert ( "Currency", Source.Currency );
	p.Insert ( "Item", Product );
	p.Insert ( "Feature", Feature );
	p.Insert ( "Package", Package );
	p.Insert ( "Prices", ? ( Prices.IsEmpty (), Source.Prices, Prices ) );
	p.Insert ( "Social", Social );
	data = getPackageData ( p );
	Capacity = data.Capacity;
	Price = data.Price;
	ProducerPrice = data.ProducerPrice;
	Computations.Units ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	updateWarning ();
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	date = Params.Date;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, Params.VendorContract, Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	data.Insert ( "ProducerPrice", ? ( Params.Social, Goods.ProducerPrice ( Params, date ), 0 ) );
	return data;
	
EndFunction 

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Packages ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	updateWarning ();
		
EndProcedure

&AtClient
Procedure PriceOnChange ( Item )

	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );

EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( ThisObject );
	Computations.Discount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( Prices.IsEmpty (), Source.Prices, Prices );
	Price = Goods.Price ( , Source.Date, prices, Product, Package, Feature, Organization, Contract, VendorContract, Source.Warehouse, Source.Currency );
	
EndProcedure 

&AtClient
Procedure DiscountRateOnChange ( Item )
	
	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure DiscountOnChange ( Item )
	
	Computations.DiscountRate ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure VATCodeOnChange ( Item )
	
	VATRate = DF.Pick ( VATCode, "Rate" );
	Computations.Total ( ThisObject, VATUse );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( ThisObject, VATUse, false );
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure

&AtClient
Procedure ProducerPriceOnChange ( Item )
	
	Computations.ExtraCharge ( ThisObject );
	
EndProcedure
