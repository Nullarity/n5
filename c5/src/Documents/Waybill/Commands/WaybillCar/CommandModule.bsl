
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "WaybillCar";
	p.Name = "WaybillCar";
	Print.Print ( p );
	
EndProcedure
