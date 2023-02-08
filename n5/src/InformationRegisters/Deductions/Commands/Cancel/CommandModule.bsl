
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	data = getData ( CommandExecuteParameters.Source );
	if ( not checkData ( data ) ) then
		return;
	endif; 
	openCanceling ( data );
	
EndProcedure

&AtClient
Function getData ( Form )
	
	result = new Structure ( "Employee, Deduction, Use" );
	source = Form.FormName;
	if ( source = "InformationRegister.Deductions.Form.Form" ) then
		if ( Form.Modified ) then
			Form.Write ();
		endif; 
		object = Form.Record;
		result.Employee = object.Employee;
		result.Deduction = object.Deduction;
		result.Use = object.Use;
	elsif ( source = "InformationRegister.Deductions.Form.Embedded" ) then
		object = Form.Items.List.CurrentData;
		if ( object = undefined ) then
			return undefined;
		endif; 
		result.Employee = DC.FindFilter ( Form.List, "Employee" ).RightValue;
		result.Deduction = object.Deduction;
		result.Use = object.Use;
	else
		return undefined;
	endif; 
	return result;

EndFunction 

&AtClient
Function checkData ( Data )
	
	if ( Data = undefined ) then
		return false;
	endif;
	if ( not Data.Use ) then
		Output.RecordAlreadyCanceled ();
		return false;
	endif; 
	return true;
	
EndFunction 

&AtClient
Procedure openCanceling ( Data )
	
	p = new Structure ( "Employee, Deduction" );
	FillPropertyValues ( p, Data );
	OpenForm ( "InformationRegister.Deductions.Form.Canceling", p );
	
EndProcedure 
