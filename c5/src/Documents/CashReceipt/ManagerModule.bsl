#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( FormType = "ObjectForm" ) then
		StandardProcessing = false;
		SelectedForm = Metadata.CommonForms.CashReceipt;
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
	if ( Env.Fields.Entry ) then
		sqlEntry ( Env );
	elsif ( Env.Fields.VendorRefund ) then
		sqlVendorRefund ( Env );
	else
		sqlPayment ( Env );
	endif;
	getTables ( Env )
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
	|	Documents.Amount as Amount, Documents.Currency as Currency,
	|	Documents.Giver as Giver, Documents.Reason as Reason, Documents.Reference as Reference, Documents.Base as Base,
	|	case when Documents.Base refs Document.Entry then true else false end as Entry,
	|	case when Documents.Base refs Document.VendorRefund then true else false end as VendorRefund
	|from Document.CashReceipt as Documents
	|where Documents.Ref = &Ref 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlEntry ( Env )
	
	s = "
	|// @Details
	|select case when Records.DimCr1 refs Catalog.Organizations then cast ( Records.DimCr1 as Catalog.Organizations ).CodeFiscal
	|			when Records.DimCr1 refs Catalog.Individuals then cast ( Records.DimCr1 as Catalog.Individuals ).PIN
	|		end as GiverCodeFiscal
	|from Document.Entry.Records as Records
	|where Records.Ref = &Base 
	|and Records.LineNumber = 1
	|;
	|// #Accounts
	|select distinct Payments.AccountCr.Code as Account
	|from Document.Entry.Records as Payments
	|where Payments.Ref = &Base 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlPayment ( Env )
	
	s = "
	|// @Details
	|select Documents.CustomerAccount.Code as Account, Documents.Customer.CodeFiscal as GiverCodeFiscal
	|from Document.Payment as Documents
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
	p.Fill ( details );
	if ( fields.Entry ) then
		p.Account = StrConcat ( Env.Accounts.UnloadColumn ( "Account" ), ", " );
	endif;
	p.AmountInWords = Conversion.AmountToWords ( fields.amount, fields.Currency );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure sqlVendorRefund ( Env )
	
	s = "
	|// @Details
	|select Documents.VendorAccount.Code as Account, Documents.Vendor.CodeFiscal as GiverCodeFiscal
	|from Document.VendorRefund as Documents
	|where Documents.Ref = &Base 
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

#endregion

#endif
