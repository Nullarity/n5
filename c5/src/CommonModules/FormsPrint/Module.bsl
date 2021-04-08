&AtClient
Procedure InvoiceRecord ( Objects ) export
	
	p = Print.GetParams ();
	p.Objects = Objects;
	p.Key = "InvoiceRecord";
	p.Name = "Invoice";
	Print.Print ( p );
	
EndProcedure

Function Check ( Reference, Status ) export
	
	if ( Status = PredefinedValue ( "Enum.FormStatuses.Printed" )
		or Status = PredefinedValue ( "Enum.FormStatuses.Submitted" ) ) then
		return true;
	else
		OutputCont.FormNotReady ( new Structure ( "Ref", Reference ), "Status", Reference );
		return false;
	endif;
	
EndFunction
