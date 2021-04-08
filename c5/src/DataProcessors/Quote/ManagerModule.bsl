#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure setContext ( Params, Env ) 

	if ( TypeOf ( Params.Reference ) = Type ( "DocumentRef.Quote" ) ) then
		table = "Quote";
	else
		table = "SalesOrder";
	endif;
	Env.Insert ( "Table", table );

EndProcedure

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	return true;
	
EndFunction

Procedure getData ( Params, Env )
	
	setContext ( Params, Env );
	sqlFields ( Env );
	getFields ( Params, Env );
	defineAmount ( Env );
	sqlTables ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	table = Env.Table;
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company,
	|	Documents.Creator.Description as Salesman, Documents.Customer.FullDescription as Customer, Constants.Currency as LocalCurrency,
	|	Documents.Currency.Description as Currency, Documents.Currency as CurrencyRef, Documents.Company.Discounts as Discounts,
	|	Contacts.BusinessPhone as Phone, Contacts.Email as Email, Documents.Company.PaymentAddress.Presentation as Address,
	|	Documents.Guarantee as Guarantee, Documents.Rate as Rate, Documents.Factor as Factor, Logos.Logo as Logo, Stamps.Stamp as Stamp,
	|	case when Logos.Logo is null then false else true end as LogoLoaded, case when Stamps.Stamp is null then false else true end as StampLoaded,
	|   case when Signatures.Signature is null then false else true end as SignatureLoaded, Signatures.Signature as Signature
	|from Document." + table + " as Documents
	|	//
	|	// Constants
	|	//
	|	left join Constants as Constants
	|	on true
	|	//
	|	// Contacts
	|	//
	|	left join Catalog.Contacts as Contacts
	|	on Contacts.Owner = Documents.Company
	|	and not Contacts.DeletionMark
	|	and Contacts.ContactType = value ( Catalog.ContactTypes.Director )
	|	//
	|	// Logos
	|	//
	|	left join InformationRegister.Logos as Logos
	|	on Logos.Company = Documents.Company
	|	//
	|	// Stamps
	|	//
	|	left join InformationRegister.Stamps as Stamps
	|	on Stamps.Company = Documents.Company
	|	//
	|	// Signatures
	|	//
	|	left join InformationRegister.Signatures as Signatures
	|	on Signatures.Individual = Documents.Creator.Employee.Individual
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Params, Env )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	fields = Env.Fields;
	total = "Total";
	vat = "VAT";
	price = "Price";
	discount = "Discount";
	if ( fields.CurrencyRef <> fields.LocalCurrency ) then
		rate = " * &Rate / &Factor";
		total = total + rate;
		vat = vat + rate;
		price = price + rate;
		discount = discount + rate;
	endif;
	list.Insert ( "Total", "cast ( " + total + " as Number ( 15, 2 ) )" );
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );
	list.Insert ( "Price", "cast ( " + price + " as Number ( 15, 2 ) )" );
	list.Insert ( "Discount", "cast ( " + discount + " as Number ( 15, 2 ) )" );
	
EndProcedure 

Procedure sqlTables ( Env )
	
	amountFields = Env.AmountFields;
	total = amountFields.Total;
	vat = amountFields.VAT;
	amount = total + " - " + vat;
	price = amountFields.Price;
	discount = amountFields.Discount;
	table = Env.Table;
	s = "
	|// #Items
	|select Items.Item.Description as Item, Items.Feature.Description as Feature, 
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as Quantity,
	|	" + total + " as Total, " + vat + " as VAT, " + price + " as Price, " + amount + " as Amount, " + discount + " as Discount
	|from Document." + table + ".Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|;
	|// #Services
	|select Services.Description as Item, Services.Feature.Description as Feature, 
	|	Services.Item.Unit.Code as Unit, Services.Quantity as Quantity, 
	|	" + total + " as Total, " + vat + " as VAT, " + price + " as Price, " + amount + " as Amount, " + discount + " as Discount
	|from Document." + table + ".Services as Services
	|where Services.Ref = &Ref
	|order by Services.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=DD" );
	if ( fields.LogoLoaded ) then
		area.Drawings.Logo.Picture = new Picture ( fields.Logo.Get () );
	endif;
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	areas = getAreas ( Env );
	header = areas.Header;
	header.Parameters.Currency = Env.Fields.Currency;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	Print.Repeat ( tabDoc );
	table = Env.Items;
	CollectionsSrv.Join ( table, Env.Services );
	accuracy = Application.Accuracy ();
	line = 0;
	area = areas.Area;
	p = area.Parameters;
	for each row in table do
		line = line + 1;
		p.Fill ( row );
		p.Line = line;
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

Function getAreas ( Env )

	header = "Table";
	row = "Row";
	if ( Options.Features () ) then
		header = header + "Feature";
		row = row + "Feature";
	endif;
	if ( Env.Fields.Discounts ) then
		header = header + "Discount";
		row = row + "Discount";
	endif;
	t = Env.T;
	return new Structure ( "Header, Area", t.GetArea ( header ), t.GetArea ( row ) );

EndFunction

Procedure putFooter ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( fields );
	p.Total = Env.Items.Total ( "Total" );
	drawings = area.Drawings;
	if ( fields.StampLoaded ) then
		drawings.Stamp.Picture = new Picture ( fields.Stamp.Get () );
	endif;
	if ( fields.SignatureLoaded ) then
		drawings.Signature.Picture = new Picture ( fields.Signature.Get () );
	endif;
	Params.TabDoc.Put ( area );
	
EndProcedure

#endif