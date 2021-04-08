&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		DocumentForm.Init ( object );
		fillNew ( Form );
	endif;
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	if ( TypeOf ( Form.Object.Ref ) = Type ( "DocumentRef.DepreciationSetup" ) ) then
		rules.Add ( "
		|Method Schedule LiquidationValue enable Object.MethodChange;
		|UsefulLife enable Object.UsefulLifeChange;
		|Expenses enable Object.ExpensesChange;
		|Acceleration enable ( Object.Method = Enum.Amortization.Decreasing and Object.MethodChange );
		|Schedule enable
		|( Object.MethodChange
		|	and ( Object.Method = Enum.Amortization.Linear or Object.Method = Enum.Amortization.Decreasing ) )
		|" );
	else
		rules.Add ( "
		|Method Rate Acceleration enable Object.MethodChange;
		|UsefulLife enable Object.UsefulLifeChange;
		|Expenses enable Object.ExpensesChange;
		|Acceleration enable ( Object.Method = Enum.Amortization.Decreasing and Object.MethodChange )
		|" );
	endif;
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	parameters = Form.Parameters;
	if ( not parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	if ( object.Department.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Department" );
		object.Company = settings.Company;
		object.Department = settings.Department;
	else
		object.Company = DF.Pick ( object.Department, "Owner" );
	endif;
	DepreciationSetupFrom.FillTable ( Form );
	
EndProcedure

&AtServer
Procedure FillTable ( Form ) export
	
	object = Form.Object;
	assets = object.Items;
	if ( object.Department.IsEmpty () ) then
		assets.Clear ();
	else
		table = FillerSrv.GetData ( Form.FillingParams () );
		assets.Load ( table );
	endif; 
	
EndProcedure 

&AtServer
Function GetFilters ( Object ) export
	
	filters = new Array ();
	deparment = Object.Department;
	if ( not deparment.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "Department", deparment ) );
	endif;
	employee = Object.Employee;
	if ( not employee.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "Employee", employee ) );
	endif;
	filters.Add ( DC.CreateParameter ( "Company", Object.Company ) );
	value = Periods.GetBalanceDate ( Object );
	if ( value <> undefined ) then
		item = DC.CreateParameter ( "Date" );
		item.Value = value;
		item.Use = true;
		filters.Add ( item );
	endif;
	return filters;
	
EndFunction

&AtClient
Procedure Fill ( Form ) export
	
	Filler.Open ( Form.FillingParams (), Form );
	
EndProcedure

&AtServer
Function Filling ( Form, Result ) export
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	items = Form.Object.Items;
	if ( Result.ClearTable ) then
		items.Clear ();
	endif; 
	for each row in table do
		newRow = items.Add ();
		newRow.Item = row.Item;
	enddo;
	return true;
	
EndFunction 

&AtClient
Procedure MethodChangeOnChange ( Form ) export
	
	resetMethod ( Form.Object );
	Appearance.Apply ( Form, "Object.MethodChange" );
	
EndProcedure

&AtClient
Procedure resetMethod ( Object )
	
	if ( Object.MethodChange ) then
		return;
	endif; 
	Object.Method = undefined;
	Object.Acceleration = undefined;
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.DepreciationSetup" ) ) then
		Object.Schedule = undefined;
		Object.LiquidationValue = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure UsefulLifeChangeOnChange ( Form ) export
	
	resetUsefulLife ( Form.Object );
	Appearance.Apply ( Form, "Object.UsefulLifeChange" );
	
EndProcedure

&AtClient
Procedure resetUsefulLife ( Object )
	
	if ( Object.UsefulLifeChange ) then
		return;
	endif; 
	Object.UsefulLife = undefined;
	
EndProcedure 

&AtClient
Procedure ExpensesChangeOnChange ( Form ) export
	
	resetExpenses ( Form.Object );
	Appearance.Apply ( Form, "Object.ExpensesChange" );
	
EndProcedure

&AtClient
Procedure resetExpenses ( Object )
	
	if ( Object.ExpensesChange ) then
		return;
	endif; 
	Object.Expenses = undefined;
	
EndProcedure 

&AtClient
Procedure MethodOnChange ( Form ) export
	
	resetFields ( Form );
	Appearance.Apply ( Form, "Object.Method" );
	
EndProcedure

&AtClient
Procedure resetFields ( Form )
	
	object = Form.Object;
	method = object.Method;
	if ( method = PredefinedValue ( "Enum.Amortization.Cumulative" )
		or method.IsEmpty () ) then
		object.Acceleration = 0;
		if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.DepreciationSetup" ) ) then
			object.Schedule = undefined;
		endif;
	elsif ( method = PredefinedValue ( "Enum.Amortization.Linear" ) ) then
		object.Acceleration = 0;
	endif; 
	
EndProcedure


