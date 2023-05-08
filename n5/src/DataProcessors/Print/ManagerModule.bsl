#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params);
	setContext ( Params, Env );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putInfo ( Params, Env );
	putTable ( Params, Env );
	putTotals ( Params, Env );
	putFooter ( Params, Env );
	putMemo ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings(Params)
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure

Procedure setContext(Params, Env)
	
	type = TypeOf ( Params.Reference );
	Env.Insert ( "IsSalesOrder", type = Type ( "DocumentRef.SalesOrder" ) );
	Env.Insert ( "IsInternalOrder", type = Type ( "DocumentRef.InternalOrder" ) );
	Env.Insert ( "IsPurchaseOrder", type = Type ( "DocumentRef.PurchaseOrder" ) );
	Env.Insert ( "IsQuote", type = Type ( "DocumentRef.Quote" ) );
	Env.Insert ( "IsInvoice", type = Type ( "DocumentRef.Invoice" ) );
	Env.Insert ( "IsVendorInvoice", type = Type ( "DocumentRef.VendorInvoice" ) );
	Env.Insert ( "Document", Metadata.FindByType ( type ).Name );
	formKey = Params.Key;
	for each item in Enums.PrintForms do
		Env.Insert ( "Print" + Conversion.EnumItemToName ( item ), item = formKey );
	enddo;
	
EndProcedure

Procedure getData ( Params, Env )
	
	sqlFields ( Env );
	getFields ( Params, Env );
	defineAmount ( Env );
	sqlItems ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields(Env)
	
	document = Env.Document;
	s = "";
	if ( Env.PrintBill ) then
		s = s + "
		|// Documents
		|select Roles.Ref as Ref, Roles.Role as Role
		|into DocumentsRoles
		|from Document.Roles as Roles
		|where not Roles.DeletionMark
		|and Roles.Action = value ( Enum.AssignRoles.Assign )
		|and Roles.Company in ( select Company from Document." + document + " where Ref = &Ref )
		|and Roles.Role in ( value ( Enum.Roles.AccountantChief ), value ( Enum.Roles.GeneralManager ) )
		|;
		|// Roles
		|select Roles.User.Employee.Individual as Individual, Roles.Role as Role
		|into Roles
		|from Document.Roles as Roles
		|	//
		|	// Last changes
		|	//
		|	join (
		|		select Roles.Role as Role, max ( Roles.Date ) as Date
		|		from Document.Roles as Roles
		|		where Roles.Ref in ( select Ref from DocumentsRoles )
		|		group by Roles.Role
		|	) as LastChanges
		|	on LastChanges.Role = Roles.Role
		|	and LastChanges.Date = Roles.Date
		|where Roles.Ref in ( select Ref from DocumentsRoles )
		|;"
	endif;
	s = s + "
	|// @Fields
	|select Documents.Date as Date, Documents.Number as Number, Documents.Company.FullDescription as Company,
	|	Documents.Currency as Currency, Documents.Rate as Rate, Documents.Factor as Factor, Documents.VATUse as VATUse,
	|	Documents.Company.PaymentAddress.Presentation as Address, Documents.Company as CompanyRef,
	|	Documents.Memo as Memo, Constants.Features and DocumentFeatures.Exists is not null as Features,
	|	Logos.Logo as Logo
	|";
	if ( Env.PrintBill ) then
		s = s + ", Documents.Company.CodeFiscal as CodeFiscal, RolesDirector.Director as Director,
		| RolesAccountant.Accountant as Accountant, Documents.Company.BankAccount.AccountNumber as AccountNumber,
		| Documents.Company.BankAccount.Bank.Description as Bank, Documents.Company.BankAccount.Bank.Code as BankCode,
		| Documents.Creator.Description as Responsible, Documents.Customer.FullDescription as Customer,
		| Documents.Company.Discounts and Documents.Discount <> 0 as Discounts";
	elsif ( Env.PrintQuote ) then
		s = s + ", Documents.Guarantee as Guarantee, Documents.Creator.Description as Responsible,
		| Documents.Customer.FullDescription as Customer,
		| Documents.Company.Discounts and Documents.Discount <> 0 as Discounts
		|"
	elsif ( Env.PrintInvoice ) then
		s = s + ", Documents.Customer.ShippingAddress.Presentation as ShippingAddress,
		| Documents.Contract.CustomerTerms.Description as Terms, Documents.SalesOrder.Number as SalesOrderNumber,
		| Documents.Shipment.Number as ShipmentNumber, Documents.PaymentDate as PaymentDate,
		| Documents.Creator.Description as Responsible, Documents.Customer.FullDescription as Customer,
		| Documents.Company.Discounts and Documents.Discount <> 0 as Discounts
		|";
	elsif ( Env.PrintSalesOrder ) then
		s = s + ", Documents.Customer.ShippingAddress.Presentation as ShippingAddress,
		| Documents.Contract.CustomerTerms.Description as Terms, Documents.DeliveryDate as DeliveryDate,
		| Documents.Creator.Description as Responsible, Documents.Customer.FullDescription as Customer,
		| Documents.Company.Discounts and Documents.Discount <> 0 as Discounts
		|";
	elsif ( Env.PrintPurchaseOrder ) then
		s = s + ", Documents.Warehouse.Address.Presentation as ShippingAddress,
		| Documents.Contract.VendorTerms.Description as Terms, Documents.DeliveryDate as DeliveryDate,
		| Documents.Manager.Description as Responsible, Documents.Vendor.FullDescription as Vendor,
		| Documents.Company.Discounts and Documents.Discount <> 0 as Discounts
		|";
	elsif ( Env.PrintInternalOrder ) then
		s = s + ", Documents.Warehouse.Address.Presentation as ShippingAddress,
		| Documents.DeliveryDate as DeliveryDate, Documents.Department.Description as Department,
		| Documents.Responsible.Description as Responsible, false as Discounts
		|";
	endif;
	s = s + "	 
	|from Document." + document + " as Documents
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|	//
	|	// Features
	|	//
	|	left join (
	|		select top 1 true as Exists
	|		from Document." + document + ".Items as Items
	|		where Items.Ref = &Ref
	|		and Items.Feature <> value ( Catalog.Features.EmptyRef )
	|		union all
	|		select top 1 true
	|		from Document." + document + ".Services as Services
	|		where Services.Ref = &Ref
	|		and Services.Feature <> value ( Catalog.Features.EmptyRef )
	|	) as DocumentFeatures
	|	on DocumentFeatures.Exists
	|	//
	|	// Logos
	|	//
	|	left join InformationRegister.Logos as Logos
	|	on Logos.Company = Documents.Company
	|";
	if ( Env.PrintBill ) then
		s = s + "
		|	//
		|	// Accountant
		|	//
		|	left join ( 
		|		select Roles.Individual.Description as Accountant
		|		from Roles as Roles
		|		where Roles.Role = value ( Enum.Roles.AccountantChief )
		|		) as RolesAccountant
		|	on true
		|	//
		|	// Director
		|	//
		|	left join ( 
		|		select Roles.Individual.Description as Director
		|		from Roles as Roles
		|		where Roles.Role = value ( Enum.Roles.GeneralManager )
		|		) as RolesDirector
		|	on true
		|";
	endif;
	s = s + "
	|where Documents.Ref = &Ref 
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getFields(Params, Env)
	
	Env.Q.SetParameter("Ref", Params.Reference);
	SQL.Perform(Env);
	
EndProcedure

Procedure defineAmount(Env)
	
	fields = Env.Fields;
	total = "Total";
	vat = "VAT";
	if ( Env.PrintInternalOrder ) then
		discountRate = "0";
		discount = "0";
	else
		discountRate = "DiscountRate";
		discount = "Discount";
	endif;
	price = "Price";
	if ( fields.Currency <> Application.Currency () ) then
		rate = " * &Rate / &Factor";
		total = total + rate;
		vat = vat + rate;
		price = price + rate;
		discount = discount + rate;
	endif;
	list = new Structure ();
	list.Insert ( "Total", "cast ( " + total + " as Number ( 15, 2 ) )" );
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );
	list.Insert ( "Price", "cast ( " + price + " as Number ( 15, 2 ) )" );
	list.Insert ( "Discount", "cast ( " + discount + " as Number ( 15, 2 ) )" );
	list.Insert ( "DiscountRate", discountRate );
	Env.Insert ( "AmountFields", list );
	
EndProcedure

Procedure sqlItems(Env)
	
	amountFields = Env.AmountFields;
	total = amountFields.Total;
	vat = amountFields.VAT;
	discount = amountFields.Discount;
	discountRate = amountFields.DiscountRate;
	price = amountFields.Price;
	amount = total + " - " + vat;
	document = Env.Document;
	s = "
	|// Items
	|select 1 as Table, Items.LineNumber as LN,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
	|	Items.QuantityPkg as Quantity,
	|	" + total + " as Total, " + vat + " as VAT, " + amount + " as Amount, " + discount + " as Discount, " + price + " as Price,
	|	Items.Feature.Description as Feature, Items.Item.FullDescription as Item, " + discountRate + " as DiscountRate
	|into Items
	|from Document." + document + ".Items as Items
	|where Items.Ref = &Ref
	|union all
	|select 2, Services.LineNumber, Services.Item.Unit.Code, Services.Quantity, " + total + ", " + vat + ", " + amount + ", " + discount + ", " + price + ", 
	|	Services.Feature.Description, Services.Description, " + discountRate + "
	|from Document." + document + ".Services as Services
	|where Services.Ref = &Ref 
	|;
	|// #Items
	|select Items.Unit as Unit, Items.Quantity as Quantity, Items.Total as Total, Items.VAT as VAT, Items.Amount as Amount, Items.Feature as Feature,
	|	Items.Price as Price, Items.Item as Item, Items.DiscountRate as DiscountRate, Items.Discount as Discount
	|from Items as Items
	|order by Items.Table, Items.LN
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getTables(Env)
	
	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter("Rate", fields.Rate);
	q.SetParameter("Factor", fields.Factor);
	SQL.Perform(Env);
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( Conversion.EnumItemToName ( Params.Key ) + "Header" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill(fields);
	p.Date = Format(fields.Date, "DLF=D");
	Print.InjectLogo ( fields.Logo, area );
	Params.TabDoc.Put(area);
	
EndProcedure

Procedure putInfo ( Params, Env )
	
	area = Env.T.GetArea ( "CurrencyAndTax" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Taxes = Print.VATInfo ( fields.VATUse, Params.SelectedLanguage );
	p.Currency = Print.CurrencyInfo ( fields.Currency, fields.Rate, fields.Factor );
	Params.TabDoc.Put(area);
	
EndProcedure

Procedure putTable(Params, Env)
	
	areas = getAreas(Env);
	tabDoc = Params.TabDoc;
	tabDoc.Put(areas.Header);
	area = areas.Area;
	p = area.Parameters;
	line = 0;
	discounts = Env.Fields.Discounts;
	amountColumn = ? ( vatIncluded ( Env ), "Total", "Amount" );
	for each row in Env.Items do
		line = line + 1;
		p.Fill(row);
		p.Line = line;
		p.Item = Print.FormatItem ( row.Item, , row.Feature );
		p.Quantity = row.Quantity;
		p.Amount = row [ amountColumn ];
		if ( discounts and row.DiscountRate > 0 ) then
			p.DiscountRate = "" + row.DiscountRate + "%";
		endif;
		tabDoc.Put(area);
	enddo;
	
EndProcedure

Function getAreas(Env)
	
	header = "Table";
	row = "Row";
	fields = Env.Fields;
	if ( fields.Discounts ) then
		header = header + "Discount";
		row = row + "Discount";
	endif;
	t = Env.T;
	return new Structure ( "Header, Area", t.GetArea ( header ), t.GetArea ( row ) );
	
EndFunction

Function vatIncluded ( Env )
	
	return Env.Fields.VATUse = 1;
	
EndFunction

Procedure putTotals ( Params, Env )
	
	prepareTotals ( Env );
	tabDoc = Params.TabDoc;
	t = Env.T;
	tabDoc.Put ( t.GetArea ( "Footer" ) );
	fields = Env.Fields;
	vatUse = fields.VATUse;
	if ( fields.Discounts ) then
		putDiscounts ( Params, Env );
	endif;
	if ( vatUse > 0 ) then
		putAmount ( Params, Env );
		putTax ( Params, Env );
	endif;
	putToPay ( Params, Env );
	
EndProcedure

Procedure prepareTotals ( Env )
	
	table = Env.Items;
	totals = new Structure ( "VAT, Discount, Amount, Total" );
	totals.Amount = table.Total ( "Amount" );
	totals.Total = table.Total ( "Total" );
	totals.Discount = table.Total ( "Discount" );
	totals.VAT = table.Total ( "VAT" );
	Env.Insert ( "Totals", totals );
	
EndProcedure

Procedure putDiscounts ( Params, Env )
	
	area = Env.T.GetArea ( "Discount" );
	p = area.Parameters;
	totals = Env.Totals;
	discount = totals.Discount;
	p.GrossAmount = ? ( vatIncluded ( Env ), totals.Total, totals.Amount ) + discount;
	p.Discount = - discount;
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putAmount ( Params, Env )
	
	area = Env.T.GetArea ( "Subtotal" );
	area.Parameters.Amount = Env.Totals.Amount;
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putTax ( Params, Env )
	
	area = Env.T.GetArea ( "Tax" );
	area.Parameters.Amount = Env.Totals.VAT;
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putToPay ( Params, Env )
	
	area = Env.T.GetArea ( "Total" );
	area.Parameters.Amount = Env.Totals.Total;
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	if ( Env.PrintQuote ) then
		putQuoteFooter ( Params, Env );
	elsif ( Env.PrintBill) then
		putSignatures ( Params, Env );
	endif;
	
EndProcedure

Procedure putQuoteFooter ( Params, Env )
	
	area = Env.T.GetArea ( "QuoteFooter" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putSignatures ( Params, Env )
	
	area = Env.T.GetArea ( "Signatures" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	p.TotalInWords = Conversion.AmountToWords ( Env.Totals.Total, fields.Currency, Params.SelectedLanguage );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putMemo ( Params, Env )
	
	memo = Env.Fields.Memo;
	if ( IsBlankString ( memo ) ) then
		return;
	endif;
	area = Env.T.GetArea ( "Memo" );
	area.Parameters.Memo = memo;
	Params.TabDoc.Put ( area );
	
EndProcedure

#endif