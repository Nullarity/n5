
&AtClient
Procedure DeleteTaxes ( Object, Employees ) export
	
	taxes = Object.Taxes;
	search = new Structure ( "Employee" );
	for each employee in Employees do
		search.Employee = employee;
		rows = taxes.FindRows ( search );
		i = rows.Count ();
		while ( i > 0 ) do
			i = i - 1;
			taxes.Delete ( rows [ i ] );
		enddo; 
	enddo;
	
EndProcedure 

&AtServer
Function FillTables ( Form, Result ) export
	
	data = Filler.Fetch ( Result );
	if ( data = undefined ) then
		return false;
	endif;
	if ( Result.ClearTable ) then
		PayrollForm.Clean ( Form );
		PayrollForm.MakeClean ( Form );
	endif; 
	object = Form.Object;
	if ( Form.CalculationVariant <> 3 ) then
		loadTable ( data.Compensations, object.Compensations );
	endif; 
	loadTable ( data.Taxes, object.Taxes );
	if ( isPayroll ( object ) ) then
		loadTable ( data.Base, object.Base );
		loadTable ( data.Advances, object.Advances );
	endif;
	fillTotals ( object );
	Form.Modified = true;
	return true;

EndFunction

&AtServer
Procedure loadTable ( Source, Destination )
	
	for each row in Source do
		newRow = Destination.Add ();
		FillPropertyValues ( newRow, row );
	enddo;

EndProcedure

Procedure Clean ( Form ) export
	
	object = Form.Object;
	if ( Form.CalculationVariant <> 3 ) then
		object.Compensations.Clear ();
		if ( isPayroll ( object ) ) then
			object.Base.Clear ();
			object.Advances.Clear ();
		endif;
	endif;
	object.Taxes.Clear ();
	
EndProcedure 

Procedure MakeClean ( Form ) export
	
	Form.Object.Dirty = false;
	Appearance.Apply ( Form, "Object.Dirty" );
	
EndProcedure 

&AtServer
Procedure fillTotals ( Object )
	
	Object.Totals.Clear ();
	employees = allEmployees ( Object );
	PayrollForm.CalcEmployees ( Object, employees );
	
EndProcedure 

&AtServer
Function allEmployees ( Object )
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payroll" ) ) then
		employees = Object.Compensations.Unload ( , "Individual" );
		taxes = Object.Taxes.Unload ( , "Individual" );
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		employees = Object.Compensations.Unload ( , "Employee" );
		taxes = Object.Taxes.Unload ( , "Employee" );
	else
		employees = Object.Compensations.Unload ( , "Individual" );
		taxes = Object.Taxes.Unload ( , "Employee" );
		taxes.Columns.Employee.Name = "Individual";
	endif; 
	CollectionsSrv.Join ( employees, taxes );
	column = employees.Columns [ 0 ].Name;
	employees.GroupBy ( column );
	return employees.UnloadColumn ( column );
	
EndFunction 

Function isPayroll ( Object )
	
	return TypeOf ( Object.Ref ) = Type ( "DocumentRef.Payroll" );
	
EndFunction 

Procedure CalcEmployees ( Object, Employees ) export
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payroll" ) ) then
		column = "Individual";
		taxColumn = "Individual";
		amount = "AccountingResult";
		payroll = true;
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		column = "Employee";
		taxColumn = "Employee";
		amount = "Amount";
		payroll = false;
	else
		column = "Individual";
		taxColumn = "Employee";
		amount = "Result";
		payroll = false;
	endif; 
	search = new Structure ( column );
	taxSearch = new Structure ( taxColumn );
	for each employee in Employees do
		search [ column ] = employee;
		taxSearch [ taxColumn ] = employee;
		compensations = Object.Compensations.FindRows ( search );
		taxes = Object.Taxes.FindRows ( taxSearch );
		row = totalsRow ( Object, employee );
		if ( compensations.Count () = 0
			and taxes.Count () = 0 ) then
			Object.Totals.Delete ( row );
			continue;
		endif;
		for each compensation in compensations do
			row.Amount = row.Amount + compensation [ amount ];
		enddo; 
		for each tax in taxes do
			method = tax.Method;
			result = tax.Result;
			if ( method = PredefinedValue ( "Enum.Calculations.IncomeTax" ) ) then
				if ( not payroll ) then
					row.IncomeTax = row.IncomeTax + result;
				endif;
			elsif ( method = PredefinedValue ( "Enum.Calculations.MedicalInsurance" ) ) then
				row.Medical = row.Medical + result;
			elsif ( method = PredefinedValue ( "Enum.Calculations.SocialInsurance" ) ) then
				row.Social = row.Social + result;
			else
				row.Other = row.Other + result;
			endif; 
		enddo; 
		if ( not payroll ) then
			row.Net = row.Amount - row.IncomeTax - row.Medical - row.Other;
		endif; 
	enddo;

EndProcedure 
	
Function totalsRow ( Object, Employee )
	
	totals = Object.Totals;
	rows = totals.FindRows ( new Structure ( "Employee", Employee ) );
	if ( rows.Count () = 0 ) then
		row = totals.Add ();
		row.Employee = Employee;
	else
		row = rows [ 0 ];
		row.Amount = 0;
		row.Other = 0;
		if ( isPayroll ( Object ) ) then
			row.Social = 0;
		else
			row.Net = 0;
			row.IncomeTax = 0;
			row.Medical = 0;
		endif; 
	endif; 
	return row;
	
EndFunction 

&AtClient
Procedure LoadRow ( Form, Params ) export
	
	object = Form.Object;
	value = Params.Value;
	if ( value = undefined ) then
		if ( Params.NewRow ) then
			Form.Object.Compensations.Delete ( Form.TableRow );
		endif;
	else
		tableRow = Form.TableRow;
		FillPropertyValues ( tableRow, value );
		PayrollForm.MakeDirty ( Form );
		employees = new Array ();
		employees.Add ( ? ( isPayroll ( object ), tableRow.Individual, tableRow.Employee ) );
		PayrollForm.CalcEmployees ( object, employees );
	endif;
	
EndProcedure 

&AtClient
Procedure SyncTables ( Form, Tables ) export
	
	tableRow = Form.TableRow;
	if ( tableRow = undefined ) then
		return;
	endif;
	object = Form.Object;
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.PayAdvances" ) ) then
		employee = tableRow.Individual;
	else
		employee = tableRow.Employee;
	endif;
	filter = new Structure ( "Employee", employee );
	items = Form.Items;
	for each table in Conversion.StringToArray ( Tables ) do
		rows = object [ table ].FindRows ( filter );
		if ( rows.Count () = 0 ) then
			return;
		endif; 
		items [ table ].CurrentRow = rows [ 0 ].GetID ();
	enddo;
	
EndProcedure 

&AtClient
Procedure MakeDirty ( Form ) export
	
	object = Form.Object;
	if ( object.Dirty ) then
		return;
	endif; 
	object.Dirty = true;
	Appearance.Apply ( Form, "Object.Dirty" );
	
EndProcedure 

&AtClient
Procedure EditRow ( Form, NewRow = false ) export
	
	if ( Form.TableRow = undefined ) then
		return;
	endif; 
	object = Form.Object;
	p = new Structure ();
	p.Insert ( "Company", object.Company );
	p.Insert ( "NewRow", NewRow );
	p.Insert ( "ReadOnly", object.Posted );
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payroll" ) ) then
		name = "Document.Payroll.Form.Row";
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		name = "Document.PayEmployees.Form.Row";
	else
		name = "Document.PayAdvances.Form.Row";
	endif; 
	OpenForm ( name, p, Form );
	
EndProcedure 

&AtClient
Procedure LoadTaxRow ( Form, Params ) export
	
	object = Form.Object;
	changedRow = Params.Value;
	if ( changedRow = undefined ) then
		if ( Params.NewRow ) then
			object.Taxes.Delete ( Form.TableTaxRow );
		endif;
	else
		tableRow = Form.TableTaxRow;
		if ( tableRow.Edit
			and not changedRow.Edit ) then
			PayrollForm.MakeDirty ( Form );
		endif; 
		FillPropertyValues ( tableRow, changedRow );
		employees = new Array ();
		employees.Add ( ? ( isPayroll ( object ), tableRow.Individual, tableRow.Employee ) );
		PayrollForm.CalcEmployees ( object, employees );
	endif;
	
EndProcedure 

&AtClient
Procedure NewRow ( Form, Clone ) export
	
	Forms.NewRow ( Form, Form.Items.Compensations, Clone );
	PayrollForm.EditRow ( Form, true );
	
EndProcedure

&AtClient
Procedure EditTaxRow ( Form, NewRow = false ) export
	
	if ( Form.TableTaxRow = undefined ) then
		return;
	endif; 
	object = Form.Object;
	p = new Structure ();
	p.Insert ( "Company", object.Company );
	p.Insert ( "NewRow", NewRow );
	p.Insert ( "ReadOnly", object.Posted );
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payroll" ) ) then
		name = "Document.Payroll.Form.TaxRow";
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		name = "Document.PayEmployees.Form.TaxRow";
	else
		name = "Document.PayAdvances.Form.TaxRow";
	endif; 
	OpenForm ( name, p, Form );
	
EndProcedure 

&AtClient
Procedure NewTaxRow ( Form, Clone ) export
	
	Forms.NewRow ( Form, Form.Items.Taxes, Clone );
	PayrollForm.EditTaxRow ( Form, true );
	
EndProcedure

&AtClient
Procedure OpenCalculations ( Form ) export
	
	object = Form.Object;
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payroll" )
		or type = Type ( "DocumentRef.PayAdvances" ) ) then
		column = "Individual";
	else
		column = "Employee";
	endif;
	rows = object.Compensations.FindRows ( new Structure ( column, Form.TableTotalsRow.Employee ) );
	if ( rows.Count () = 0 ) then
		return;
	endif; 
	items = Form.Items;
	items.Pages.CurrentPage = items.PageCalculations;
	Form.CurrentItem = items.Compensations;
	items.Compensations.CurrentRow = rows [ 0 ].GetID ();
	
EndProcedure 

&AtServer
Procedure BeforeWrite ( CurrentObject, WriteParameters, CopyOf = undefined ) export
	
	resetDirty ( CurrentObject, WriteParameters );
	passCopy ( CurrentObject, CopyOf );
	calcTotals ( CurrentObject );
	
EndProcedure 

&AtServer
Procedure resetDirty ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.WriteMode = DocumentWriteMode.Posting ) then
		CurrentObject.Dirty = false;
	endif; 
	
EndProcedure 

&AtServer
Procedure passCopy ( CurrentObject, CopyOf )
	
	if ( CurrentObject.IsNew () and ValueIsFilled ( CopyOf ) ) then
		CurrentObject.AdditionalProperties.Insert ( Enum.AdditionalPropertiesCopyOf (), CopyOf ); 
	endif;

EndProcedure

&AtServer
Procedure calcTotals ( CurrentObject )
	
	if ( isPayroll ( CurrentObject ) ) then
		CurrentObject.Amount = CurrentObject.Totals.Total ( "Amount" );
	else
		CurrentObject.Amount = CurrentObject.Totals.Total ( "Net" );
	endif; 
	
EndProcedure 
