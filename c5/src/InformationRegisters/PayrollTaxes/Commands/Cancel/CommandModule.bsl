
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
	
	result = new Structure ( "Tax, Limit, Rate, Use" );
	source = Form.FormName;
	if ( source = "InformationRegister.PayrollTaxes.Form.Form" ) then
		if ( Form.Modified ) then
			Form.Write ();
		endif; 
		object = Form.Record;
		result.Tax = object.Tax;
		result.Limit = object.Limit;
		result.Rate = object.Rate;
		result.Use = object.Use;
	elsif ( source = "ChartOfCalculationTypes.Taxes.Form.Form" ) then
		object = Form.Items.PayrollTaxes.CurrentData;
		if ( object = undefined ) then
			return undefined;
		endif; 
		result.Tax = Form.Object.Ref;
		result.Limit = object.Limit;
		result.Rate = object.Rate;
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
	
	p = new Structure ( "Tax, Limit, Rate" );
	FillPropertyValues ( p, Data );
	OpenForm ( "InformationRegister.PayrollTaxes.Form.Canceling", p );
	
EndProcedure 
