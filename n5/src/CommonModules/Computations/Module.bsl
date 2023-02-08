
Procedure Units ( TableRow ) export
	
	TableRow.Quantity = TableRow.QuantityPkg * TableRow.Capacity;
	
EndProcedure

Procedure Packages ( TableRow ) export
	
	TableRow.QuantityPkg = TableRow.Quantity / ? ( TableRow.Capacity = 0, 1, TableRow.Capacity );
	
EndProcedure

Procedure Amount ( TableRow ) export
	
	discount = getProperty ( TableRow, "Discount" );
	amount = getGrossAmount ( TableRow );
	TableRow.Amount = amount - discount;
	
EndProcedure

Function getProperty ( TableRow, Name )
	
	found = exists ( TableRow, Name );
	return ? ( found, TableRow [ Name ], 0 );
	
EndFunction 

Function exists ( TableRow, Name )
	
	rowType = TypeOf ( TableRow );
	if ( rowType = Type ( "FormDataCollectionItem" )
		or rowType = Type ( "Structure" ) ) then
		return TableRow.Property ( Name );
	elsif ( rowType = Type ( Enum.FrameworkManagedForm () ) ) then
		return TableRow.Items.Find ( Name ) <> undefined;
	elsif ( rowType = Type ( "ValueTableRow" ) ) then
		return TableRow.Owner ().Columns.Find ( Name ) <> undefined;
	else
		#if ( Server ) then
			meta = Metadata.FindByType ( TypeOf ( TableRow ) );
			return meta <> undefined and meta.Attributes.Find ( Name ) <> undefined;
		#endif
	endif; 
	
EndFunction 

Function getGrossAmount ( TableRow )
	
	quantity = getProperty ( TableRow, "Quantity" );
	quantityPkg = getProperty ( TableRow, "QuantityPkg" );
	if ( quantityPkg <> 0 ) then
		return TableRow.Price * quantityPkg;
	elsif ( quantity <> 0 ) then
		return TableRow.Price * quantity;
	else
		return TableRow.Price;
	endif; 
	
EndFunction 

Procedure Discount ( TableRow ) export
	
	amount = getGrossAmount ( TableRow );
	TableRow.Discount = amount / 100 * TableRow.DiscountRate;
	
EndProcedure

Procedure DiscountRate ( TableRow ) export
	
	amount = getGrossAmount ( TableRow );
	TableRow.DiscountRate = ? ( amount = 0, 100, TableRow.Discount / amount * 100 );
	
EndProcedure

&AtClient
Procedure Price ( TableRow ) export
	
	quantityPkg = ? ( exists ( TableRow, "QuantityPkg" ), TableRow.QuantityPkg, TableRow.Quantity );
	quantity = ? ( quantityPkg = 0, 1, quantityPkg );
	if ( exists ( TableRow, "DiscountRate" ) ) then
		factor = quantity * ( 1 - 0.01 * TableRow.DiscountRate );
	else
		factor = quantity;
	endif; 
	TableRow.Price = ? ( factor = 0, 0, TableRow.Amount / factor );
	
EndProcedure

Procedure Total ( TableRow, Use, CalcVAT = true ) export
	
	if ( CalcVAT ) then
		vat ( TableRow, Use );
	endif; 
	amount = TableRow.Amount;
	tax = TableRow.VAT;
	if ( Use = 2 ) then
		total = amount + tax;
	else
		total = amount;
	endif;
	TableRow.Total = total;
	
EndProcedure

Procedure vat ( TableRow, Use )
	
	amount = TableRow.Amount;
	rate = TableRow.VATRate;
	if ( Use = 1 ) then
		tax = amount - amount * 100 / ( 100 + rate );
	elsif ( Use = 2 ) then
		tax = amount / 100 * rate;
	else
		tax = 0;
	endif;
	TableRow.VAT = tax;
	
EndProcedure

Procedure ExtraCharge ( TableRow ) export

	producerPrice = TableRow.ProducerPrice;
	if ( not TableRow.Social
		or producerPrice = 0 ) then
		TableRow.ExtraCharge = 0;
	else
		quantityPkg = ? ( exists ( TableRow, "QuantityPkg" ), TableRow.QuantityPkg, TableRow.Quantity );
		quantity = ? ( quantityPkg = 0, 1, quantityPkg );
		price = ( TableRow.Total - TableRow.VAT ) / quantity;
		TableRow.ExtraCharge = ( price - producerPrice ) / producerPrice * 100;
	endif;

EndProcedure
