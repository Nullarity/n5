
&AtClient
Procedure CommandProcessing ( Waybill, CommandExecuteParameters )
	
	p = new Structure ( "Basis", Waybill );
	OpenForm ( "Document.WriteOff.ObjectForm", p );
	
EndProcedure
