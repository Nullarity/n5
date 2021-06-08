&AtClient
Procedure LoadRow ( Form, Params ) export
	
	object = Form.Object;
	tableRow = Form.TableRow;
	FillPropertyValues ( tableRow, Params.Value );
	table = object.Additions;
	rows = table.FindRows ( new Structure ( "Employee", tableRow.Employee ) );
	for each row in rows do
		table.Delete ( row );
	enddo; 
	for each row in Params.Additions do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
	enddo; 
	filterAdditions ( Form );
	
EndProcedure 

&AtClient
Procedure filterAdditions ( Form )
	
	items = Form.Items;
	tableRow = Form.TableRow;
	if ( tableRow = undefined ) then
		items.Additions.RowFilter = undefined;
	else
		filter = new Structure ( "Employee", tableRow.Employee );
		items.Additions.RowFilter = new FixedStructure ( filter );
	endif; 
	
EndProcedure 

&AtClient
Procedure EditRow ( Form, NewRow = false ) export
	
	if ( Form.TableRow = undefined ) then
		return;
	endif; 
	p = new Structure ();
	object = Form.Object;
	p.Insert ( "Company", object.Company );
	p.Insert ( "row", NewRow );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.Hiring" ) ) then
		name = "Document.Hiring.Form.Row";
	else
		name = "Document.EmployeesTransfer.Form.Row";
	endif; 
	OpenForm ( name, p, Form, , , , new NotifyDescription ( "RecordClosed", ThisObject, Form ) );
	
EndProcedure 

&AtClient
Procedure RecordClosed ( Result, Form ) export
	
	if ( Result = undefined ) then
		return;
	endif;
	HiringForm.LoadRow ( Form, Result );

EndProcedure 

&AtClient
Procedure OnActivateRow ( Form, Item ) export
	
	Form.TableRow = Item.CurrentData;
	filterAdditions ( Form );
	
EndProcedure

&AtClient
Procedure CleanAdditions ( Form ) export
	
	object = Form.Object;
	table = object.Additions;
	rows = table.FindRows ( new Structure ( "Employee", Form.TableRow.Employee ) );
	for each row in rows do
		table.Delete ( row );
	enddo; 
	
EndProcedure 

&AtClient
Procedure SetIndividual ( TableRow ) export
	
	employee = TableRow.Employee;
	if ( employee.IsEmpty () ) then
		TableRow.Individual = undefined;
	else
		TableRow.Individual = DF.Pick ( employee, "Individual" );
	endif; 
	
EndProcedure 

&AtServer
Function CheckDoubles ( Object ) export
	
	doubles = Collections.GetDoubles ( Object.Employees, "Employee" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.EmployeeDuplicated ( , Output.Row ( "Employees", row.LineNumber, "Employee" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 
