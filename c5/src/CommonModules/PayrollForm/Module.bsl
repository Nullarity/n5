&AtServer
Procedure SetAccounts ( Object ) export
	
	table = getAccounts ( Object );
	for each row in table do
		parameter = row.Parameter;
		value = row.Value;
		if ( parameter = ChartsOfCharacteristicTypes.Settings.EmployeesOtherDebt ) then
			Object.EmployeesDebt = value;
		elsif ( parameter = ChartsOfCharacteristicTypes.Settings.EmployerOtherDebt ) then
			Object.EmployerDebt = value;
		elsif ( parameter = ChartsOfCharacteristicTypes.Settings.DepositLiabilities ) then
			Object.DepositLiabilities = value;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getAccounts ( Object )
	
	accounts = new Array ();
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.EmployeesOtherDebt )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.EmployerOtherDebt )" );
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.PayEmployees" ) ) then
		accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.DepositLiabilities )" );
	endif;
	s = "
	|select Settings.Parameter as Parameter, Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter in ( " + StrConcat ( accounts, "," ) + ") ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure DeleteTaxes ( Object, Employee ) export
	
	taxes = Object.Taxes;
	rows = taxes.FindRows ( new Structure ( "Employee", Employee ) );
	i = rows.Count ();
	while ( i > 0 ) do
		i = i - 1;
		taxes.Delete ( rows [ i ] );
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
	last = data.Ubound ();
	object = Form.Object;
	if ( Form.CalculationVariant <> 3 ) then
		fillTable ( object.Compensations, data [ last ].Select () );
	endif; 
	fillTable ( object.Taxes, data [ last - 1 ].Select () );
	if ( isPayroll ( object ) ) then
		fillTable ( object.Base, data [ last - 2 ].Select () );
	endif;
	fillTotals ( object );
	return true;

EndFunction

Procedure Clean ( Form ) export
	
	object = Form.Object;
	if ( Form.CalculationVariant <> 3 ) then
		object.Compensations.Clear ();
	endif;
	object.Taxes.Clear ();
	if ( isPayroll ( object ) ) then
		object.Base.Clear ();
	endif;
	
EndProcedure 

Procedure MakeClean ( Form ) export
	
	Form.Object.Dirty = false;
	Appearance.Apply ( Form, "Object.Dirty" );
	
EndProcedure 

&AtServer
Procedure fillTable ( Table, Selection )
	
	while ( Selection.Next () ) do
		row = Table.Add ();
		FillPropertyValues ( row, selection );
	enddo; 
	
EndProcedure 

&AtServer
Procedure fillTotals ( Object )
	
	Object.Totals.Clear ();
	employees = allEmployees ( Object );
	for each employee in employees do
		PayrollForm.CalcEmployee ( Object, employee );
	enddo; 
	
EndProcedure 

&AtServer
Function allEmployees ( Object )
	
	column = ? ( isPayroll ( Object ), "Individual", "Employee" );
	employees = Object.Compensations.Unload ( , column );
	CollectionsSrv.Join ( employees, Object.Taxes.Unload ( , column ) );
	employees.GroupBy ( column );
	return employees.UnloadColumn ( column );
	
EndFunction 

Function isPayroll ( Object )
	
	return TypeOf ( Object.Ref ) = Type ( "DocumentRef.Payroll" );
	
EndFunction 

Procedure CalcEmployee ( Object, Employee ) export
	
	if ( isPayroll ( Object ) ) then
		column = "Individual";
		amount = "AccountingResult";
		payroll = true;
	else
		column = "Employee";
		amount = "Amount";
		payroll = false;
	endif; 
	search = new Structure ( column, Employee );
	compensations = Object.Compensations.FindRows ( search );
	taxes = Object.Taxes.FindRows ( search );
	row = totalsRow ( Object, Employee );
	if ( compensations.Count () = 0
		and taxes.Count () = 0 ) then
		Object.Totals.Delete ( row );
		return;
	endif;
	for each compensation in compensations do
		row.Amount = row.Amount + compensation [ amount ];
	enddo; 
	for each tax in taxes do
		method = tax.Method;
		result = tax.Result;
		if ( method = PredefinedValue ( "Enum.Calculations.IncomeTax" )
			or method = PredefinedValue ( "Enum.Calculations.FixedIncomeTax" ) ) then
			if ( not payroll ) then
				row.IncomeTax = row.IncomeTax + result;
			endif;
		elsif ( method = PredefinedValue ( "Enum.Calculations.MedicalInsurance" ) ) then
			row.Medical = row.Medical + result;
		elsif ( method = PredefinedValue ( "Enum.Calculations.MedicalInsuranceEmployee" ) ) then
			row.MedicalEmployee = row.MedicalEmployee + result;
		elsif ( method = PredefinedValue ( "Enum.Calculations.SocialInsurance" ) ) then
			row.Social = row.Social + result;
		elsif ( method = PredefinedValue ( "Enum.Calculations.SocialInsuranceEmployee" ) ) then
			if ( Payroll ) then
				row.SocialEmployee = row.SocialEmployee + result;
			else
				row.Social = row.Social + result;
			endif; 
		else
			row.Other = row.Other + result;
		endif; 
	enddo; 
	if ( payroll ) then
		row.Net = row.Amount - row.Medical - row.Social - row.Other;
	else
		row.Net = row.Amount - row.IncomeTax - row.MedicalEmployee - row.Social - row.Other;
	endif; 
	
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
		row.Social = 0;
		row.Medical = 0;
		row.Other = 0;
		row.Net = 0;
		if ( isPayroll ( Object ) ) then
			row.SocialEmployee = 0;
		else
			row.IncomeTax = 0;
			row.MedicalEmployee = 0;
		endif; 
	endif; 
	return row;
	
EndFunction 

&AtClient
Procedure LoadRow ( Form, Params ) export
	
	value = Params.Value;
	if ( value = undefined ) then
		if ( Params.NewRow ) then
			Form.Object.Compensations.Delete ( Form.TableRow );
		endif;
	else
		tableRow = Form.TableRow;
		FillPropertyValues ( tableRow, value );
		PayrollForm.SyncTaxes ( Form );
		PayrollForm.MakeDirty ( Form );
		PayrollForm.CalcEmployee ( Form.Object, tableRow.Employee );
	endif;
	
EndProcedure 

&AtClient
Procedure SyncTaxes ( Form ) export
	
	tableRow = Form.TableRow;
	if ( tableRow = undefined ) then
		return;
	endif;
	filter = new Structure ( "Employee", tableRow.Employee );
	rows = Form.Object.Taxes.FindRows ( filter );
	if ( rows.Count () = 0 ) then
		return;
	endif; 
	Form.Items.Taxes.CurrentRow = rows [ 0 ].GetID ();
	
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
	if ( isPayroll ( object ) ) then
		name = "Document.Payroll.Form.Row";
	else
		name = "Document.PayEmployees.Form.Row";
	endif; 
	OpenForm ( name, p, Form );
	
EndProcedure 

&AtClient
Procedure LoadTaxRow ( Form, Params ) export
	
	changedRow = Params.Value;
	if ( changedRow = undefined ) then
		if ( Params.NewRow ) then
			Form.Object.Taxes.Delete ( Form.TableTaxRow );
		endif;
	else
		tableRow = Form.TableTaxRow;
		if ( tableRow.Edit
			and not changedRow.Edit ) then
			PayrollForm.MakeDirty ( Form );
		endif; 
		FillPropertyValues ( tableRow, changedRow );
		PayrollForm.CalcEmployee ( Form.Object, tableRow.Employee );
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
	if ( isPayroll ( object ) ) then
		name = "Document.Payroll.Form.TaxRow";
	else
		name = "Document.PayEmployees.Form.TaxRow";
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
	column = ? ( isPayroll ( object ), "Individual", "Employee" );
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
Procedure BeforeWrite ( CurrentObject, WriteParameters ) export
	
	resetDirty ( CurrentObject, WriteParameters );
	calcTotals ( CurrentObject );
	
EndProcedure 

&AtServer
Procedure resetDirty ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.WriteMode = DocumentWriteMode.Posting ) then
		CurrentObject.Dirty = false;
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
