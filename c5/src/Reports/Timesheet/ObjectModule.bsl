#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var TabDoc;
var Line;
var Employee;
var Position;
var Division;

Procedure AfterOutput () export

	init ();
	mergeRows ();
	
EndProcedure

Procedure init () 

	TabDoc = Params.Result;
	Line = 0;
	row = TabDoc.FixedTop + 1;
	Employee = new Structure ( "Last, Row, Column", , row, 2 );
	Position = new Structure ( "Last, Row, Column", , row, 3 );
	Division = new Structure ( "Last, Row, Column", , row, 4 );

EndProcedure

Procedure mergeRows () 

	row = TabDoc.FixedTop + 1;
	lastRow = TabDoc.TableHeight - 1;
	for i = row to lastRow do
		if ( TabDoc.Area ( i, 5, i, 5 ).Text = "" ) then
			break;
		endif;
		mergeEmployee ( i );
		merge ( Position, i );
		merge ( Division, i );
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
	else
		Employee.Last = value;
		Employee.Row = Row;
		Position.Last = undefined;
		Division.Last = undefined;
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

#endif