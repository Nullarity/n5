
#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ItemsPurchase.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Printing

Function Print ( Params, Env ) export
	
	setPageSettings ( Params );
	getData ( Params, Env );
	if ( not FormsPrint.Check ( Params.Reference, Env.Fields.Status ) ) then
		return false;
	endif;
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	sqlFields ( Env );
	getFields ( Env, Params );
	sqlItems ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select ItemsPurchase.Base as Base, ItemsPurchase.FormNumber as Number, ItemsPurchase.Date as Date, 
	|	ItemsPurchase.Company.FullDescription as Company, ItemsPurchase.Company.CodeFiscal as CompanyCodeFiscal, 
	|	ItemsPurchase.Company.PaymentAddress as CompanyAddress, ItemsPurchase.Company as CompanyRef,
	|	ItemsPurchase.Responsible.LastName + "" "" + ItemsPurchase.Responsible.FirstName as Responsible,
	|	Invoice.Vendor.LastName + "" "" + Invoice.Vendor.FirstName as Vendor, 
	|	Invoice.Vendor.CodeFiscal as VendorPIN, Invoice.Vendor.Series as VendorSeries,
	|	Invoice.Vendor.Number as VendorNumber, Invoice.Vendor.Issued as VendorIssued,
	|	Invoice.Vendor.IssuedBy as VendorIssuedBy, Invoice.Vendor.Address as VendorAddress,
	|	Invoice.Contract.DateStart as ContractDate, Invoice.Contract.Code as ContractNumber,
	|	ItemsPurchase.Series as Series, Invoice.Currency as Currency, Invoice.Amount as Amount, 
	|	ItemsPurchase.IncomeTaxAmount as IncomeTaxAmount, ItemsPurchase.Advance as Advance,
	|	ItemsPurchase.Total as Total, ItemsPurchase.Status as Status 
	|from Document.ItemsPurchase as ItemsPurchase
	|	//
	|	// Invoice
	|	//
	|	join Document.VendorInvoice as Invoice
	|	on Invoice.Ref = ItemsPurchase.Base
	|where ItemsPurchase.Ref = &Ref";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env, Params )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );	
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.Item.FullDescription as Item, Items.Feature.Description as Feature,  
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
	|	Items.QuantityPkg as Quantity, Items.Price as Price, Items.Total as Amount
	|from Document.VendorInvoice.Items as Items
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Base", Env.Fields.Base );
	SQL.Perform ( Env );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	fields = Env.Fields;
	data = Responsibility.Get ( fields.Date, fields.CompanyRef, "GeneralManager" );
	director = data.GeneralManager;
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( fields );
	p.VendorInfo = getVendorInfo ( Env );
	if ( director <> undefined ) then
		if ( ValueIsFilled ( director.LastName ) ) then
			director = director.LastName + " " + director.FirstName;	
		else
			director = director.FirstName;
		endif;
		p.Director = director;
	endif;
	Params.TabDoc.Put ( area );
	
EndProcedure

Function getVendorInfo ( Env )
	
	fields = Env.Fields;
	parts = new Array ();
	value = fields.VendorPIN;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	value = fields.VendorSeries;
	if ( value <> "" ) then
		parts.Add ( Output.IDSeries () + " " + value );
	endif; 
	value = fields.VendorNumber;
	if ( value <> "" ) then
		parts.Add ( Output.IDNumber () + value );
	endif; 
	value = fields.VendorIssuedBy;
	if ( value <> "" ) then
		parts.Add ( Output.IDIssuedBy () + " " + value );
	endif; 
	value = fields.VendorIssued;
	if ( value <> Date ( 1, 1, 1 ) ) then
		parts.Add ( Output.IDIssued () + " " + Format ( value, "DLF=D" ) );
	endif;
	value = fields.VendorAddress;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	return StrConcat ( parts, ", " );
	
EndFunction

Procedure putTable ( Params, Env )
	
	t = Env.T;
	header = t.GetArea ( "TableHeader" );
	area = t.GetArea ( "TableRow" );
	footer = t.GetArea ( "TableFooter" );
	header.Parameters.Fill ( Env.Fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	table = Env.Items;
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		p.Item = Print.FormatItem ( row.Item, , row.Feature );
		tabDoc.Put ( area );
	enddo;
	rowsCount = table.Count ();
	maxRowsCount = 23;
	area = t.GetArea ( "EmptyRow" );
	while ( rowsCount < maxRowsCount ) do
		tabDoc.Put ( area );
		rowsCount = rowsCount + 1;
	enddo;
	footer.Parameters.Amount = table.Total ( "Amount" );
	tabDoc.Put ( footer );
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( fields );
	p.AmountInWords = Conversion.AmountToWords ( fields.Amount, fields.Currency );
	if ( fields.IncomeTaxAmount > 0 ) then
		p.IncomeTaxAmountInWords = Conversion.AmountToWords ( fields.IncomeTaxAmount, fields.Currency );
	endif;
	if ( fields.Advance > 0 ) then
		p.AdvanceInWords = Conversion.AmountToWords ( fields.Advance, fields.Currency );
	endif;
	if ( fields.Total > 0 ) then
		p.TotalInWords = Conversion.AmountToWords ( fields.Total, fields.Currency );
	endif;
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif
