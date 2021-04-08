
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	if ( not checkWaybill ( CommandParameter ) ) then
		return;
	endif; 
	openWriteOff ( CommandParameter );
	
EndProcedure

&AtClient
Function checkWaybill ( Waybill )
	
	flag = DF.Pick ( Waybill, "FuelInventory" );
	if ( flag ) then
		return true;
	endif; 
	OutputCont.WaybillWriteOffError ();
	return false;
	
EndFunction 

&AtClient
Procedure openWriteOff ( Waybill )
	
	p = new Structure ( "Basis", Waybill );
	OpenForm ( "Document.WriteOff.ObjectForm", p );
	
EndProcedure 