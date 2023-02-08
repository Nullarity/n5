// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setTitle ();
	fill ();
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	Title = "" + Parameters.Reference;
	
EndProcedure

&AtServer
Procedure fill ()
	
	process = Parameters.Process;
	if ( process.IsEmpty () ) then
		if ( TypeOf ( Parameters.Reference ) = Type ( "DocumentRef.SalesOrder" ) ) then
			Chart = BusinessProcesses.SalesOrder.GetFlowChart ();
		else
			Chart = BusinessProcesses.InternalOrder.GetFlowChart ();
		endif; 
	else
		obj = process.GetObject ();
		Chart = obj.GetFlowchart ();
		if ( obj.Completed ) then
			finish = Chart.GraphicalSchemaItems.Finish;
			finish.BackColor = StyleColors.NegativeTextColor;
			finish.TextColor = StyleColors.FormBackColor;
		endif; 
	endif; 
	Chart [ "GridEnabled" ] = false;
	
EndProcedure