
&AtClient
Procedure CommandProcessing ( Customer, CommandExecuteParameters )
	
	if ( not checkCustomer ( Customer ) ) then
		return;
	endif; 
	openDocument ( Customer );
	
EndProcedure

&AtClient
Function checkCustomer ( Customer )
	
	if ( DF.Pick ( Customer, "IsFolder" ) ) then
		Output.SelectCustomer ();
		return false;
	endif; 
	return true;
	
EndFunction 

&AtClient
Procedure openDocument ( Customer )
	
	values = new Structure ();
	values.Insert ( "Customer", Customer );
	p = new Structure ( "FillingValues", values );
	OpenForm ( "Document.Invoice.ObjectForm", p );
	
EndProcedure
