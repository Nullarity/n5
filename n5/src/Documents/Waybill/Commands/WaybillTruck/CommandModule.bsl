
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "WaybillTruck";
	p.Template = "WaybillTruck";
	Print.Print ( p );
	
EndProcedure
