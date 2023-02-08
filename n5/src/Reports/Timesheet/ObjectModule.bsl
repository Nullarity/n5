#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var TabDoc;
var NoLine;
var Line;
var EmployeeID;
var Employee;
var Position;
var Division;
var Time;
var TabDocWidth;

Procedure OnPrepare ( Template ) export
	
	Reporter.MakeFlat ( Template );
	
EndProcedure

Procedure AfterOutput () export

	init ();
	adjustView ();
	mergeRows ();
	hideDivision ();
	
EndProcedure

Procedure init () 

	NoLine = new Line ( SpreadsheetDocumentCellLineType.None );
	TabDoc = Params.Result;
	TabDocWidth = TabDoc.TableWidth;
	Line = 0;
	row = TabDoc.FixedTop + 1;
	EmployeeID = new Structure ( "Last, Row, Column", , row, 2 );
	Employee = new Structure ( "Last, Row, Column", , row, 3 );
	Position = new Structure ( "Last, Row, Column", , row, 4 );
	Division = new Structure ( "Last, Row, Column", , row, 5 );
	Time = new Structure ( "Last, Row, Column", , row, 6 );

EndProcedure

Procedure adjustView ()
	
	fixHeader ();
	fixWidth ();
	daysToMonths ();
		
EndProcedure

Procedure fixHeader ()
	
	end = TabDoc.FixedTop - 2;
	column = Division.Column;
	for i = 1 to end do
		TabDoc.Area ( i, 1, i, column ).Merge ();	
	enddo;

EndProcedure

Procedure fixWidth ()
	
	TabDoc.Area ( "C1" ).ColumnWidth = 3;
	TabDoc.Area ( "C" + EmployeeID.Column ).ColumnWidth =
		Metadata.Catalogs.Employees.StandardAttributes.Code.Type.StringQualifiers.Length;
	
EndProcedure

Procedure daysToMonths ()
	
	settings = Params.Settings;
	period = DC.GetParameter ( settings, "Period" ).Value;
	date = BegOfMonth ( period.StartDate );
	dateEnd = EndOfMonth ( period.EndDate );
	while ( date < dateEnd ) do
		Print.Entitle ( Params.Result, Format ( date, "DF=MMMM" ), "###" + Format ( date ,"DF=MM" ) );
		date = AddMonth ( date, 1 );
	enddo;
	
EndProcedure

Procedure mergeRows () 

	row = TabDoc.FixedTop + 1;
	lastRow = TabDoc.TableHeight - 1;
	employeeColumn = Employee.Column;
	for i = row to lastRow do
		if ( TabDoc.Area ( i, employeeColumn, i, employeeColumn ).Text = "" ) then
			break;
		endif;
		mergeEmployee ( i );
		merge ( EmployeeID, i );
		merge ( Position, i );
		merge ( Division, i );
		merge ( Time, i );
	enddo;
	
EndProcedure

Procedure mergeEmployee ( Row ) 

	column = Employee.Column;
	value = TabDoc.Area ( Row, column, Row, column ).Text;
	if ( Employee.Last = value ) then
		lastRow = Employee.Row;
		TabDoc.Area ( lastRow, column, Row, column ).Merge ();
		lineArea = TabDoc.Area ( lastRow, 1, Row, 1 );
		lineArea.Merge ();
		lineArea.Text = Line;
		column = Time.Column;
		TabDoc.Area ( Row - 1, column, Row - 1, TabDocWidth ).BottomBorder = NoLine;
		TabDoc.Area ( Row, column, Row, TabDocWidth ).TopBorder = NoLine;
	else
		Employee.Last = value;
		Employee.Row = Row;
		Position.Last = undefined;
		Division.Last = undefined;
		EmployeeID.Last = undefined;
		Time.Last = undefined;
		Line = Line + 1;
		TabDoc.Area ( Row, 1, Row, 1 ).Text = Line;
	endif;

EndProcedure

Procedure merge ( Area, Row ) 

	column = Area.Column;
	value = TabDoc.Area ( Row, column, Row, column ).Text;
	if ( Area.Last = value ) then
		TabDoc.Area ( Area.Row, column, Row, column ).Merge ();
	else
		Area.Last = value;
		Area.Row = Row;
	endif;

EndProcedure

Procedure hideDivision ()
	
	column = "C" + Division.Column;
	TabDoc.Area ( column + ":" + column ).Group ( "Department" );
	TabDoc.ShowColumnGroupLevel ( 0 );
	
EndProcedure

#endif