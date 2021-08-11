&AtClient
Procedure MethodOnChange ( Form ) export
	
	object = Form.Object;
	PayrollItemForm.SetDescription ( object );
	resetBase ( object );
	if ( TypeOf ( object.Ref ) = Type ( "ChartOfCalculationTypesRef.Compensations" ) ) then
		resetHourlyRate ( object );
	else
		resetNet ( object );
	endif; 
	Appearance.Apply ( Form, "Object.Method" );
	
EndProcedure

&AtClient
Procedure resetBase ( Object )
	
	method = Object.Method;
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "ChartOfCalculationTypesRef.Compensations" ) ) then
		if ( method = PredefinedValue ( "Enum.Calculations.Percent" )
			or method = PredefinedValue ( "Enum.Calculations.Vacation" )
			or method = PredefinedValue ( "Enum.Calculations.ExtendedVacation" )
			or method = PredefinedValue ( "Enum.Calculations.SickDays" ) ) then
		else
			Object.BaseCalculationTypes.Clear ();
		endif; 
	else
		if ( Object.Method = PredefinedValue ( "Enum.Calculations.FixedAmount" ) ) then
			Object.BaseCalculationTypes.Clear ();
		endif;
	endif; 

EndProcedure 

&AtClient
Procedure resetHourlyRate ( Object )
	
	if ( Object.Method = PredefinedValue ( "Enum.Calculations.MonthlyRate" ) ) then
		Object.HourlyRate = PredefinedValue ( "Enum.HourlyRate.Monthly" );
	else
		Object.HourlyRate = undefined;
	endif; 

EndProcedure 

&AtClient
Procedure resetNet ( Object )

	method = Object.Method;
	if ( method <> PredefinedValue ( "Enum.Calculations.Percent" )
		and method <> PredefinedValue ( "Enum.Calculations.FixedAmount" ) ) then
		Object.Net = false;
	endif; 

EndProcedure

Procedure SetDescription ( Object ) export
	
	Object.Description = Object.Method;
	setCode ( Object );
	
EndProcedure 

Procedure setCode ( Object )
	
	Object.Code = Conversion.DescriptionToCode ( Object.Description );
	
EndProcedure 

&AtClient
Procedure DescriptionOnChange ( Form ) export
	
	setCode ( Form.Object );
	
EndProcedure
