// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	filterDepartments ();
	Options.SetAccuracy ( ThisObject, "Quantity" );
	Options.Company ( ThisObject, Source.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Department enable Performer = Enum.Performers.Department;
	|Discount DiscountRate enable DiscountApplicable;
	|VATCode VAT show VATUse > 0;
	|Total show VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Source = Parameters.Source;
	TableRow = Parameters.TableRow;
	FillPropertyValues ( ThisObject, TableRow );
	DiscountApplicable = Source.Type.SalesOrder;
	VATUse = Source.VATUse;
	VATCode = TableRow.VATCode;
	VATRate = TableRow.VATRate;
	VAT = TableRow.VAT;
	Total = TableRow.Total;
	
EndProcedure

&AtServer
Procedure filterDepartments ()
	
	list = new Array ();
	list.Add ( new ChoiceParameter ( "Filter.Owner", Source.Company ) );
	Items.Department.ChoiceParameters = new FixedArray ( list );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	OrderRows.ResetPerformer ( ThisObject );
	NotifyChoice ( getResult () );

EndProcedure

&AtClient
Function getResult ()
	
	FillPropertyValues ( TableRow, ThisObject );
	return TableRow;
	
EndFunction

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	Price = Goods.Price ( , Source.Date, Prices, Item, , Feature, Source.Customer, Source.Contract, , Source.Warehouse, Source.Currency );
	
EndProcedure 

&AtClient
Procedure PriceOnChange ( Item )
	
	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure DiscountRateOnChange ( Item )
	
	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure DiscountOnChange ( Item )
	
	Computations.DiscountRate ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( ThisObject );
	Computations.Discount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure PerformerOnChange ( Item )
	
	OrderRows.ResetDepartment ( ThisObject );
	Appearance.Apply ( ThisObject, "Performer" );
	
EndProcedure

&AtClient
Procedure VATCodeOnChange ( Item )
	
	VATRate = DF.Pick ( VATCode, "Rate" );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( ThisObject, VATUse, false );
	
EndProcedure
