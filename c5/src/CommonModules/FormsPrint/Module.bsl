&AtClient
Procedure InvoiceRecord ( Objects ) export
	
	p = Print.GetParams ();
	p.Objects = Objects;
	p.Key = "InvoiceRecord";
	p.Template = "Invoice";
	Print.Print ( p );
	
EndProcedure

&AtServer
Function Check ( Reference, Status ) export
	
	if ( forGovernment ( Reference ) ) then
		Output.EFacturaForGovernment ( , "Customer", Reference );
		return false;
	else
		if ( Status = PredefinedValue ( "Enum.FormStatuses.Printed" )
			or Status = PredefinedValue ( "Enum.FormStatuses.Submitted" ) ) then
			return true;
		else
			Output.FormNotReady ( new Structure ( "Ref", Reference ), "Status", Reference );
			return false;
		endif;
	endif;
	
EndFunction

&AtServer
Function forGovernment ( Reference )
	
	s = "
	|select top 1 1
	|from Document.InvoiceRecord
	|where Ref = &Ref
	|and cast ( Customer as Catalog.Organizations ).Government
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Reference );
	return not q.Execute ().IsEmpty ();
	
EndFunction