
&AtClient
Procedure CommandProcessing ( Vendor, CommandExecuteParameters )
	
	if ( not checkVendor ( Vendor ) ) then
		return;
	endif; 
	openDocument ( Vendor );
	
EndProcedure

&AtClient
Function checkVendor ( Vendor )
	
	if ( DF.Pick ( Vendor, "IsFolder" ) ) then
		Output.SelectVendor ();
		return false;
	endif; 
	return true;
	
EndFunction 

&AtClient
Procedure openDocument ( Vendor )
	
	values = new Structure ();
	values.Insert ( "Vendor", Vendor );
	p = new Structure ( "FillingValues", values );
	OpenForm ( "Document.PurchaseOrder.ObjectForm", p );
	
EndProcedure
