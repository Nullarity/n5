// This is not real test.
// The scenario is used like a resource for filling testing data

Procedure Make ()

	area = getArea ();
	draw ();

EndProcedure

Procedure C1 ()

	result = sum ( "A1:B1" );

EndProcedure

Procedure P1 ()

	result = getLast ( "C1" );

EndProcedure