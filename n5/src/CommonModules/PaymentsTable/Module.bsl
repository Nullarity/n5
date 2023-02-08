&AtServer
Procedure Fill ( Object ) export
	
	table = getPayments ( Object );
	if ( table.Count () = 0 ) then
		return;
	endif; 
	Object.Payments.Load ( table );
	PaymentsTable.Calc ( Object );
	
EndProcedure
 
&AtServer
Function getPayments ( Object )
	
	type = TypeOf ( Object.Ref );
	s = "
	|select Payments.Option as Option, Payments.Variant as Variant, Payments.Percent as Percent,
	|	case when Payments.Variant = value ( Enum.PaymentVariants.Prepayment ) then &Date else null end as PaymentDate
	|from Catalog.Terms.Payments as Payments
	|where Payments.Ref in ( select ";
	if ( type = Type ( "DocumentRef.Invoice" )
		or type = Type ( "DocumentRef.Quote" )
		or type = Type ( "DocumentRef.SalesOrder" ) ) then
		s = s + "CustomerTerms";
	else
		s = s + "VendorTerms";
	endif; 
	s = s + " from Catalog.Contracts where Ref = &Contract )
	|order by Payments.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Date", BegOfDay ( Periods.GetDocumentDate ( Object ) ) );
	table = q.Execute ().Unload ();
	return table;
	
EndFunction

Procedure Calc ( Object ) export
	
	Collections.Distribute ( Object.Amount, Object.Payments, "Percent", "Amount" );
	
EndProcedure

&AtClient
Procedure Fix ( Object ) export
	
	amount = Object.Payments.Total ( "Amount" );
	if ( amount <> Object.Amount ) then
		Calc ( Object );
	endif; 
	
EndProcedure

&AtServer
Function Check ( Object ) export
	
	if ( tableIsEmpty ( Object ) ) then
		return false;
	endif; 
	if ( dateDoubled ( Object ) ) then
		return false;
	endif; 
	if ( incorrectPeriod ( Object ) ) then
		return false;
	endif; 
	return true;
	
EndFunction

&AtServer
Function tableIsEmpty ( Object )
	
	meta = Object.Ref.Metadata ();
	p = new Structure ();
	p.Insert ( "Table", meta.TabularSections.Payments.Presentation () );
	if ( Object.Amount > 0 and Object.Payments.Count () = 0 ) then
		Output.TableIsEmpty ( p, "Payments" );
		return true;
	endif; 
	return false;
	
EndFunction
 
&AtServer
Function dateDoubled ( Object )
	
	meta = Object.Ref.Metadata ();
	p = new Structure ( "Table, Values" );
	p.Table = meta.TabularSections.Payments.Presentation ();;
	doubleRows = CollectionsSrv.GetDuplicates ( Object.Payments, "Option, PaymentDate" );
	if ( doubleRows <> undefined ) then
		for each row in doubleRows do
			p.Values = "" + row.Option + ", " + row.PaymentDate;
			Output.TableDoubleRows ( p, "Payments" );
		enddo; 
		return true;
	endif;
	return false;
	
EndFunction

&AtServer
Function incorrectPeriod ( Object )
	
	error = false;
	startDate = BegOfDay ( Periods.GetDocumentDate ( Object ) );
	for each row in Object.Payments do
		if ( not Periods.Ok ( startDate, row.PaymentDate ) ) then
			Output.PaymentDateError ( , Output.Row ( "Payments", row.LineNumber, "PaymentDate" ) );
			error = true;
		endif; 
	enddo; 
	return error;
	
EndFunction

&AtServer
Function CheckQuote ( Object ) export
	
	if ( dateDoubled ( Object ) ) then
		return false;
	endif; 
	if ( incorrectPeriod ( Object ) ) then
		return false;
	endif; 
	return true;
	
EndFunction
