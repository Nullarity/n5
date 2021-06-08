&AtClient
var TableRow export;
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
	if ( Parameters.row ) then
		Schedule = Application.Schedule ();
	endif;

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
	if ( Parameters.row ) then
		TableRow.DateStart = Object.Date;
		TableRow.Schedule = Schedule;
		TableRow.Currency = Currency;
		TableRow.Employment = PredefinedValue ( "Enum.Employment.Main" );
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
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure

&AtClient
Procedure DateStartOnChange ( Item )
	
	сalcDateEnd ();
	
EndProcedure

&AtClient
Procedure сalcDateEnd ()
	
	start = TableRow.DateStart;
	duration = TableRow.Duration;
	if ( start = Date ( 1, 1, 1 ) ) then
		return;
	elsif ( duration = 0 ) then
		TableRow.DateEnd = undefined;
	else
		TableRow.DateEnd = AddMonth ( start, duration );
	endif; 
	
EndProcedure 

&AtClient
Procedure calcDuration ()
	
	emptyDate = Date ( 1, 1, 1 );
	start = TableRow.DateStart;
	end = TableRow.DateEnd;
	if ( start = emptyDate
		or end = emptyDate ) then
		TableRow.Duration = 0;
	else
		TableRow.Duration = toMonths ( end ) - toMonths ( start );
	endif; 
	
EndProcedure 

&AtClient
Function toMonths ( Date )
	
	return 12 * Year ( Date ) + Month ( Date );
	
EndFunction 

&AtClient
Procedure DurationOnChange ( Item )
	
	сalcDateEnd ();
	
EndProcedure

&AtClient
Procedure DateEndOnChange ( Item )
	
	calcDuration ();
	
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
	
EndProcedure 
