Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Report" );
	p.Insert ( "Variant", "#Fill" );
	p.Insert ( "Filters" );
	p.Insert ( "Processor", "Filling" );
	p.Insert ( "ProposeClearing", true );
	p.Insert ( "ClearTable", true );
	p.Insert ( "Background", false );
	p.Insert ( "Batch", false );
	p.Insert ( "CloseOnErrors", false );
	return p;
	
EndFunction 

Function Result () export
	
	p = new Structure ();
	p.Insert ( "Address", "" );
	p.Insert ( "ClearTable", true );
	p.Insert ( "Completed" );
	return p;
	
EndFunction 

&AtClient
Procedure Open ( Params, Caller ) export
	
	callback = callbackParams ( Params, Caller );
	p = new Structure ( "Caller, Filling", Caller.UUID, Params );
	OpenForm ( "Report.Common.Form.Filling", p, Caller, , , , new NotifyDescription ( "Filling", ThisObject, callback ) );
	
EndProcedure 

&AtClient
Function callbackParams ( Params, Caller )
	
	p = new Structure ();
	p.Insert ( "Report", Params.Report );
	p.Insert ( "Variant", Params.Variant );
	p.Insert ( "Processor", Params.Processor );
	p.Insert ( "Caller", Caller );
	return p;
	
EndFunction 

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	ExecuteNotifyProcessing ( new NotifyDescription ( Params.Processor, Params.Caller, Params ), Result );

EndProcedure 

&AtClient
Procedure ProcessData ( Params, Caller ) export
	
	id = Caller.UUID;
	resultAddress = "";
	FillerSrv.StartProcess ( Params, id, resultAddress );
	result = Filler.Result ();
	result.Address = resultAddress;
	callback = callbackParams ( Params, Caller );
	p = new Structure ( "Callback, Result", callback, Result );
	Progress.Open ( id, Caller, new NotifyDescription ( "ProcessComplete", ThisObject, p ) );
	
EndProcedure

&AtClient
Procedure ProcessComplete ( Result, Params ) export
	
	Filler.Filling ( Params.Result, Params.Callback );
	
EndProcedure 

&AtServer
Function Fetch ( Result ) export
	
	table = GetFromTempStorage ( Result.Address );
	if ( table = undefined
		or table.Count () = 0 ) then
		return undefined;
	else
		return table;
	endif;
	
EndFunction