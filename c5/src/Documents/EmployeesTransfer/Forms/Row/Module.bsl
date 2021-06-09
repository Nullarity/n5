&AtClient
var TableRow export;
&AtServer
var TableRow;
&AtServer
var Data;
&AtClient
var AdditionsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	loadParams ();
	Options.Company ( ThisObject, Object.Company );
	
EndProcedure

&AtServer
Procedure init ()
	
	Currency = Application.Currency ();

EndProcedure 

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	
EndProcedure

&AtClient
Procedure loadData ()
	
	owner = FormOwner.Object;
	Object.Date = owner.Date;
	TableRow = Object.Employees.Add ();
	FillPropertyValues ( TableRow, FormOwner.Items.Employees.CurrentData );
	if ( Parameters.NewRow ) then
		TableRow.Date = Object.Date;
	else
		table = Object.Additions;
		rows = owner.Additions.FindRows ( new Structure ( "Employee", TableRow.Employee ) );
		for each row in rows do
			newRow = table.Add ();
			FillPropertyValues ( newRow, row );
		enddo; 
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	HiringRowForm.OK ( ThisObject );
	
EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	if ( TableRow.Employee.IsEmpty () ) then
		return;
	endif; 
	readData ();
	
EndProcedure

&AtServer
Procedure readData ()
	
	TableRow = Object.Employees [ 0 ];
	getData ();
	readLocation ();
	readCompensations ();

EndProcedure 

&AtServer
Procedure getData ()
	
	s = "
	|// Location
	|select Personnel.Department as Department, Personnel.Expenses as Expenses, Personnel.Position as Position,
	|	Personnel.Schedule as Schedule, Employee.Individual as Individual
	|from InformationRegister.Personnel.SliceLast ( , Employee = &Employee ) as Personnel
	|;
	|// Compensations
	|select Rates.Compensation as Compensation, Rates.Currency as Currency, Rates.Rate as Rate,
	|	case
	|		when Rates.Compensation.Method in (
	|			value ( Enum.Calculations.HourlyRate ),
	|			value ( Enum.Calculations.MonthlyRate )
	|			)
	|		then true
	|		else false
	|	end as Main
	|from InformationRegister.EmployeeRates.SliceLast ( , Employee = &Employee ) as Rates
	|where Rates.Actual
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", TableRow.Employee );
	result = q.ExecuteBatch ();
	Data = new Structure ();
	Data.Insert ( "Location", result [ 0 ].Unload () );
	Data.Insert ( "Compensations", result [ 1 ].Unload () );

EndProcedure

&AtServer
Procedure readLocation ()
	
	location = Data.Location;
	if ( location.Count () = 0 ) then
		return;
	endif; 
	FillPropertyValues ( TableRow, location [ 0 ] );
	
EndProcedure 

&AtServer
Procedure readCompensations ()
	
	employee = TableRow.Employee;
	additions = Object.Additions;
	date = Object.Date;
	additions.Clear ();
	for each row in Data.Compensations do
		if ( row.Main ) then
			FillPropertyValues ( TableRow, row );
			TableRow.Action = Enums.Changes.Nothing;
		else
			addon = additions.Add ();
			FillPropertyValues ( addon, row );
			addon.Employee = employee;
			addon.Action = Enums.Changes.Nothing;
			addon.Date = date;
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure FieldOnChange ( Item )
	
	resetAction ( TableRow );

EndProcedure

&AtClient
Procedure resetAction ( Source )
	
	if ( Source.Action = PredefinedValue ( "Enum.Changes.Nothing" ) ) then
		Source.Action = PredefinedValue ( "Enum.Changes.Change" );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Table Additions

&AtClient
Procedure ObjectAdditionsOnActivateRow ( Item )
	
	AdditionsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ObjectAdditionsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow and not Clone ) then
		initAddition ();
	endif; 
	
EndProcedure

&AtClient
Procedure initAddition ()
	
	AdditionsRow.Currency = Currency;
	AdditionsRow.Date = Object.Date;
	
EndProcedure 

&AtClient
Procedure ObjectAdditionsFieldOnChange ( Item )
	
	resetAction ( AdditionsRow );
	
EndProcedure
