#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( FormType = "ObjectForm" ) then
		StandardProcessing = false;
		SelectedForm = Metadata.CommonForms.CashVoucher;
	endif; 
	
EndProcedure

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	put ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	type = TypeOf ( Env.Fields.Base );
	if ( type = Type ( "DocumentRef.Entry" ) ) then
		sqlEntry ( Env );
	elsif ( type = Type ( "DocumentRef.VendorPayment" ) ) then
		sqlVendorPayment ( Env );
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		sqlPayEmployees ( Env );
	elsif ( type = Type ( "DocumentRef.Refund" ) ) then
		sqlRefund ( Env );
	endif;
	getTables ( Env )
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
	|	Documents.Receiver as Receiver, Documents.Reason as Reason, Documents.Reference as Reference, Documents.Base as Base, Documents.ID as ID,
	|	Documents.Amount as Amount, Documents.Currency as Currency,
	|	case when Documents.Base refs Document.Entry then true else false end as Entry, 
	|	case when Documents.Base refs Document.VendorPayment then true else false end as VendorPayment
	|from Document.CashVoucher as Documents
	|where Documents.Ref = &Ref 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlEntry ( Env )
	
	s = "
	|// #Details
	|select distinct Payments.AccountDr.Code as Account
	|from Document.Entry.Records as Payments
	|where Payments.Ref = &Base
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlVendorPayment ( Env )
	
	s = "
	|// @Details
	|select Documents.VendorAccount.Code as Account,
	|	Documents.IncomeTaxRate as IncomeTaxRate, Documents.IncomeTaxAmount as IncomeTaxAmount
	|from Document.VendorPayment as Documents
	|where Documents.Ref = &Base 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlPayEmployees ( Env )
	
	s = "
	|// @Details
	|select Documents.DepositLiabilities.Code as Account
	|from Document.PayEmployees as Documents
	|where Documents.Ref = &Base 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure getTables ( Env )
	
	q = Env.Q;
	q.SetParameter ( "Base", Env.Fields.Base );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Procedure put ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill ( fields );
	details = Env.Details;
	if ( fields.Entry ) then
		p.Account = StrConcat ( details.UnloadColumn ( "Account" ), ", " );
	else
		p.Fill ( details );
	endif;
	words = new Array ();
	words.Add ( Conversion.AmountToWords ( fields.Amount, fields.Currency ) );
	if ( fields.VendorPayment
		and details.IncomeTaxRate > 0 ) then
		words.Add ( Output.IncomeTaxRetained ( new Structure ( "Rate, Amount", details.IncomeTaxRate, Format ( details.IncomeTaxAmount, "NFD=2" ) ) ) );	
	endif;
	p.AmountInWords = StrConcat ( words, " " );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure sqlRefund ( Env )
	
	s = "
	|// @Details
	|select Documents.CustomerAccount.Code as Account
	|from Document.Refund as Documents
	|where Documents.Ref = &Base 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

#endregion

#endif
