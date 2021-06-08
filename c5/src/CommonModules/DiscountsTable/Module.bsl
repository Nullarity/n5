&AtServer
Procedure Load ( Object ) export
		
	sale = TypeOf ( Object.Ref ) = Type ( "DocumentRef.Invoice" );
	data = getDiscounts ( Object, sale );
	table = discountsVAT ( data );
	order = ? ( sale, "SalesOrder", "PurchaseOrder" );
	discounts = Object.Discounts; 
	discounts.Clear ();
	item = Application.Discounts ();
	accounts = AccountsMap.Item ( item, Object.Company, Object.Warehouse, "Income, VAT" );
	useVAT = Object.VATUse > 0;
	for each row in table do
		newRow = discounts.Add ();
		newRow [ order ] = row.Document; 
		newRow.Item = item; 
		newRow.VATCode = row.VATCode;
		rate = row.VATRate;
		newRow.VATRate = rate; 
		newRow.Amount = row.Amount;
		if ( useVAT ) then
			calcRowVAT ( newRow );
		endif;
		newRow.Income = accounts.Income; 
		newRow.VATAccount = accounts.VAT; 
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
		document = "Document.SalesOrder";
	else
		register = "AccumulationRegister.VendorDiscounts";
		document = "Document.PurchaseOrder";
	endif; 
	s = "
	|// #Orders
	|select Orders.Ref as Document, Orders.VATCode as VATCode, Orders.VATCode.Rate as VATRate,
	|	sum ( Orders.Total ) as Amount
	|from (
	|	select Items.Ref as Ref, Items.VATCode as VATCode, Items.Total as Total
	|	from " + document + ".Items as Items
	|	where Items.Ref in ( &Orders )
	|	union all
	|	select Services.Ref, Services.VATCode, Services.Total
	|	from " + document + ".Services as Services
	|	where Services.Ref in ( &Orders )
	|) as Orders
	|group by Orders.Ref, Orders.VATCode
	|;
	|// #Discounts
	|select Discounts.Document as Document, sum ( Discounts.Amount ) as Amount
	|from (
	|	select Discounts.Document as Document, Discounts.Amount as Amount
	|	from " + register + " as Discounts
	|	where Discounts.Document in ( &Orders )
	|	and Discounts.Period < &Date
	|	union all
	|	select Discounts.Detail, - Discounts.Amount
	|	from " + register + " as Discounts
	|	where Discounts.Detail in ( &Orders )
	|	and Discounts.Period < &Date
	|	) as Discounts
	|group by Discounts.Document
	|having sum ( Discounts.Amount ) > 0
	|order by Discounts.Document.Date
	|";
	data = SQL.Create ( s );
	q = data.Q;
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Date", Periods.GetDocumentDate ( Object ) );
	q.SetParameter ( "Orders", InvoiceForm.GetOrders ( Object, not Sale ) );
	SQL.Perform ( data, false );
	return data;
	
EndFunction 

&AtServer
Function discountsVAT ( Data )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "Document" );
	p.Insert ( "DistribColumnsTable1", "Amount" );
	p.Insert ( "KeyColumn", "Amount" );
	p.Insert ( "AssignСоlumnsTаble1", "Document" );
	p.Insert ( "AssignСоlumnsTаble2", "VATCode, VATRate" );
	discounts = data.Discounts;
	amountType = Metadata.Documents.Invoice.TabularSections.Discounts.Attributes.Amount.Type;
	CollectionsSrv.Adjust ( discounts, "Amount", amountType );
	table = CollectionsSrv.Combine ( discounts, data.Orders, p );
	return table;
	
EndFunction

&AtClient
Procedure ApplyItem ( Form ) export
	
	object = Form.Object;
	row = Form.Items.Discounts.CurrentData;
	data = DiscountsTableSrv.GetData ( row.Item, object.Company, object.Warehouse );
	row.Income = data.IncomeAccount;
	row.VATAccount = data.VATAccount;
	row.VATCode = data.VAT;
	row.VATRate = data.Rate;
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

&AtServer
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