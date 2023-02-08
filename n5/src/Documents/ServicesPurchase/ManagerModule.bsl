
#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ServicesPurchase.Synonym, Data, Presentation, StandardProcessing );
	
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
	|select ServicesPurchase.Base as Base, ServicesPurchase.FormNumber as Number, ServicesPurchase.Date as Date, 
	|	ServicesPurchase.Company.FullDescription as Company, ServicesPurchase.Company.CodeFiscal as CompanyCodeFiscal, 
	|	isnull ( ServicesPurchase.Company.PaymentAddress.Description, """" ) as CompanyAddress, ServicesPurchase.Company as CompanyRef,
	|	ServicesPurchase.Responsible.LastName + "" "" + ServicesPurchase.Responsible.FirstName as Responsible,
	|	Invoice.Vendor.LastName as VendorLastName, Invoice.Vendor.FirstName as VendorFirstName, 
	|	Invoice.Vendor.CodeFiscal as VendorPIN, Invoice.Vendor.Series as VendorSeries,
	|	Invoice.Vendor.Number as VendorNumber, Invoice.Vendor.Issued as VendorIssued,
	|	Invoice.Vendor.IssuedBy as VendorIssuedBy, isnull ( Invoice.Vendor.Address.Description, """" ) as VendorAddress,
	|	Invoice.Contract.DateStart as ContractDate, Invoice.Contract.Code as ContractCode,
	|	ServicesPurchase.Series as Series, Invoice.Currency as Currency, Invoice.Amount as Amount,
	|	ServicesPurchase.Surcharges as Surcharges, ServicesPurchase.Discount as Discount,
	|	ServicesPurchase.IncomeTaxAmount as IncomeTaxAmount, ServicesPurchase.Advance as Advance,
	|	ServicesPurchase.IncomeTaxAmount + ServicesPurchase.Advance as Deductions, 
	|	ServicesPurchase.Surcharges - ServicesPurchase.Discount as SurchargesMinusDiscount, 
	|	ServicesPurchase.Paid as Paid, ServicesPurchase.Total as Total, ServicesPurchase.Status as Status, 
	|	ServicesPurchase.AdditionalInfo as AdditionalInfo, ServicesPurchase.AttachedDocuments as AttachedDocuments
	|from Document.ServicesPurchase as ServicesPurchase
	|	//
	|	// Invoice
	|	//
	|	join Document.VendorInvoice as Invoice
	|	on Invoice.Ref = ServicesPurchase.Base
	|where ServicesPurchase.Ref = &Ref";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env, Params )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );	
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Services
	|select Services.Ref.Date as Date, Services.Item.FullDescription as Item, Services.Feature.Description as Feature,  
	|	Services.Item.Unit.Code as Unit, Services.Quantity as Quantity,
	|	case when Services.Quantity = 0 then Services.Total else Services.Total / Services.Quantity end as Price,
	|	Services.Total as Amount
	|from Document.VendorInvoice.Services as Services
	|where Services.Ref = &Base
	|order by Services.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Base", Env.Fields.Base );
	SQL.Perform ( Env );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Header" );
	vendorInfo = splitString ( getVendorInfo ( Env ), 45 );
	companyInfo = splitString ( getCompanyInfo ( Env ), 45 );
	p = area.Parameters;
	p.Fill ( fields );
	p.VendorInfo1 = vendorInfo.First;
	p.VendorInfo2 = vendorInfo.Second;
	p.CompanyInfo1 = companyInfo.First;
	p.CompanyInfo2 = companyInfo.Second;
	Params.TabDoc.Put ( area );
	
EndProcedure

Function getVendorInfo ( Env )
	
	fields = Env.Fields;
	parts = new Array ();
	value = fields.VendorFirstName;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	value = fields.VendorLastName;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	value = fields.VendorAddress;
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
	return StrConcat ( parts, ", " );
	
EndFunction

Function getCompanyInfo ( Env )
	
	fields = Env.Fields;
	parts = new Array ();
	value = fields.Company;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	value = fields.CompanyAddress;
	if ( value <> "" ) then
		parts.Add ( value );
	endif;
	return StrConcat ( parts, ", " );
	
EndFunction

Function splitString ( Str, MaxLen )
	
	result = new Structure ( "First, Second", "", "" );
	len = StrLen ( Str );
	if ( len > MaxLen ) then
		maxStr = Left ( Str, MaxLen );
		direction = SearchDirection.FromEnd;
		lastComma = StrFind ( maxStr, ",", direction );
		lastSpace = StrFind ( maxStr, " ", direction );
		index = ? ( lastComma = 0, ? ( lastSpace = 0, MaxLen, lastSpace ), lastComma );
		result.First = TrimAll ( Left ( Str, index + 1 ) );
		result.Second = TrimAll ( Mid ( Str, index + 1 ) );
	else
		result.First = Str;
	endif;
	return result;
	
EndFunction

Procedure putTable ( Params, Env )
	
	t = Env.T;
	header = t.GetArea ( "TableHeader" );
	area = t.GetArea ( "TableRow" );
	footer = t.GetArea ( "TableFooter" );
	header.Parameters.Fill ( Env.Fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	table = Env.Services;
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		p.Item = Print.FormatItem ( row.Item, , row.Feature );
		tabDoc.Put ( area );
	enddo;
	rowsCount = table.Count ();
	maxRowsCount = 14;
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
	if ( fields.Surcharges > 0 ) then
		p.SurchargesInWords = Conversion.AmountToWords ( fields.Surcharges, fields.Currency );
	endif;
	if ( fields.Discount > 0 ) then
		p.DiscountInWords = Conversion.AmountToWords ( fields.Discount, fields.Currency );
	endif;
	if ( fields.SurchargesMinusDiscount <> 0 ) then
		p.SurchargesMinusDiscountInWords = Conversion.AmountToWords ( fields.SurchargesMinusDiscount, fields.Currency );
	endif;
	if ( fields.Paid > 0 ) then
		p.PaidInWords = Conversion.AmountToWords ( fields.Paid, fields.Currency );
	endif;
	if ( fields.Deductions > 0 ) then
		p.DeductionsInWords = Conversion.AmountToWords ( fields.Deductions, fields.Currency );
	endif;
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
