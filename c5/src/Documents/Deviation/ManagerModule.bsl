#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Deviation.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeHours ( Env );
	makeBankedHours ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlHours ( Env );
	sqlBankedHours ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlHours ( Env )
	
	s = "
	|// #Hours
	|select Employees.Employee as Employee, Employees.Day as Day, Employees.Time as Time, Employees.Minutes as Minutes
	|from Document.Deviation.Employees as Employees
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlBankedHours ( Env )
	
	s = "
	|// #BankedHours
	|select Employees.Employee as Employee, Employees.Day as Day, Employees.Time as Time, Employees.Minutes as Minutes
	|from Document.Deviation.Employees as Employees
	|where Employees.Ref = &Ref
	|and Employees.Time in ( value ( Enum.Time.Banked ), value ( Enum.Time.BankedUse ) )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makeHours ( Env )

	recordset = Env.Registers.Hours;
	for each row in Env.Hours do
		movement = recordset.Add ();
		movement.Employee = row.Employee;
		movement.Day = row.Day;
		movement.Time = row.Time;
		movement.Minutes = row.Minutes;
	enddo;
	
EndProcedure

Procedure makeBankedHours ( Env )

	recordset = Env.Registers.BankedHours;
	banked = Enums.Time.Banked;
	for each row in Env.BankedHours do
		if ( row.Time = banked ) then
			movement = recordset.Add ();
		else
			movement = recordset.AddExpense ();
		endif; 
		movement.Employee = row.Employee;
		movement.Period = row.Day;
		movement.Minutes = row.Minutes;
	enddo;
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Hours.Write = true;
	registers.BankedHours.Write = true;
	
EndProcedure

#endregion

#endif