Procedure OK ( Form ) export
	
	Form.FormOwner.Modified = true;
	Form.Close ( getResult ( Form ) );
	
EndProcedure

Function getResult ( Form )
	
	result = new Structure ();
	result.Insert ( "Value", Form.TableRow );
	result.Insert ( "Additions", getAdditions ( Form ) );
	return result;
	
EndFunction 

Function getAdditions ( Form )
	
	rows = new Array ();
	employee = Form.TableRow.Employee;
	for each row in Form.Object.Additions do
		row.Employee = employee;
		rows.Add ( row );
	enddo; 
	return rows;

EndFunction 
