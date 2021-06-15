&AtServer
Procedure Load ( Object ) export
		
	sale = TypeOf ( Object.Ref ) = Type ( "DocumentRef.Invoice" );
	item = Application.Discounts ();
	accounts = AccountsMap.Item ( item, Object.Company, Object.Warehouse, "Income, VAT" );
	useVAT = Object.VATUse > 0;
	table = Object.Discounts; 
	table.Clear ();
	discounts = getDiscounts ( Object, sale );
	for each discount in discounts do
		vatBase = getBase ( discount );
		for each base in vatBase do
			newRow = table.Add ();
			newRow.Document = discount.Document; 
			newRow.Detail = discount.Detail; 
			newRow.Item = item; 
			newRow.VATCode = base.VATCode;
			rate = base.VATRate;
			newRow.VATRate = rate; 
			newRow.Amount = base.Amount;
			if ( useVAT ) then
				calcRowVAT ( newRow );
			endif;
			newRow.Income = accounts.Income; 
			newRow.VATAccount = accounts.VAT; 
		enddo;
	enddo;
	
EndProcedure

Procedure calcRowVAT ( Row )
	
	amount = Row.Amount;
	Row.VAT = amount - Round ( ( amount * 100 ) / ( 100 + Row.VATRate ), 2 );
	
EndProcedure

&AtServer
Function getDiscounts ( Object, Sale )
	
	if ( Sale ) then
		register = "AccumulationRegister.Discounts";
		discountDebts = "AccumulationRegister.DiscountDebts";
		orders = InvoiceForm.GetOrders ( Object, false );
	else
		register = "AccumulationRegister.VendorDiscounts";
		discountDebts = "AccumulationRegister.VendorDiscountDebts";
		orders = InvoiceForm.GetOrders ( Object, true );
	endif; 
	s = "
	|select Discounts.Document as Document, Discounts.Detail as Detail, sum ( Discounts.Amount ) as Amount
	|from (
	|	select Discounts.Document as Document, undefined as Detail, Discounts.Amount as Amount
	|	from " + register + " as Discounts
	|	where Discounts.Document in ( &Orders )
	|	and Discounts.Period < &Date
	|	union all
	|	select Discounts.Detail, undefined, - Discounts.Amount
	|	from " + register + " as Discounts
	|	where Discounts.Detail in ( &Orders )
	|	and Discounts.Period < &Date
	|	union all
	|	select DiscountDebts.Document, DiscountDebts.Detail, DiscountDebts.AmountBalance
	|	from " + discountDebts + ".Balance ( &Date, Contract = &Contract";
	if ( orders.Count () > 0 ) then
		s = s + " and Document in ( &Orders )";	
	endif;
	s = s + " ) as DiscountDebts
	|	where DiscountDebts.AmountBalance > 0
	|	) as Discounts
	|group by Discounts.Document, Discounts.Detail
	|having sum ( Discounts.Amount ) > 0
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Date", Periods.GetDocumentDate ( Object ) );
	q.SetParameter ( "Orders", orders );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Function getBase ( Row )
	
	base = ? ( Row.Detail = undefined, Row.Document, Row.Detail );
	name = base.Metadata ().FullName ();
	s = "
	|select Items.VATCode as VATCode, Items.VATCode.Rate as VATRate, sum ( Items.Total ) as Total
	|from (
	|	select VATCode as VATCode, Total as Total from " + name + ".Items where Ref = &Ref
	|	union all 
	|	select VATCode, Total from " + name + ".Services where Ref = &Ref
	|	) as Items
	|group by Items.VATCode
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", base );
	table = q.Execute ().Unload ();
	type = Metadata.Documents.Invoice.TabularSections.Discounts.Attributes.Amount.Type;
	CollectionsSrv.Adjust ( table, "Total", type );
	Collections.Distribute ( Row.Amount, table, "Total", "Amount" );
	return table;
	
EndFunction

&AtClient
Procedure ApplyItem ( Form ) export
	
	object = Form.Object;
	row = Form.Items.Discounts.CurrentData;
	invoiceRecord = TypeOf ( object.Ref ) = Type ( "DocumentRef.InvoiceRecord" );
	if ( invoiceRecord ) then
		warehouse = object.LoadingPoint;
	else
		warehouse = object.Warehouse;
	endif;
	data = DiscountsTableSrv.GetData ( row.Item, object.Company, warehouse );
	row.VATCode = data.VAT;
	row.VATRate = data.Rate;
	if ( not invoiceRecord ) then
		row.Income = data.IncomeAccount;
		row.VATAccount = data.VATAccount;
	endif;
	DiscountsTable.CalcVAT ( Form );
	
EndProcedure

&AtClient
Procedure CalcVAT ( Form ) export
	
	row = Form.Items.Discounts.CurrentData;
	if ( Form.Object.VATUse = 0 ) then
		row.VAT = 0;
	else
		calcRowVAT ( row );
	endif;
	
EndProcedure

&AtClient
Procedure SetRate ( Form ) export
	
	row = Form.Items.Discounts.CurrentData;
	row.VATRate = DF.Pick ( row.VATCode, "Rate" );
	
EndProcedure

Procedure RecalcVAT ( Form ) export
	
	object = Form.Object;
	useVAT = object.VATuse > 0;
	for each row in object.Discounts do
		if ( useVAT ) then
			calcRowVAT ( row );
		else
			row.VAT = 0;
		endif;
	enddo; 
	
EndProcedure