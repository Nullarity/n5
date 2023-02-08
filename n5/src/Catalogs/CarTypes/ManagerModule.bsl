
Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	if ( Parameters.Property ( "Car" ) ) then
		StandardProcessing = false;
		fillByCar ( ChoiceData, Parameters.Car );
	endif; 
	
EndProcedure

Procedure fillByCar ( ChoiceData, Car )
	
	ChoiceData = new ValueList ();
	table = getTrailers ( Car );
	for each row in table do
		ChoiceData.Add ( row.Trailer, row.TrailerPresentation );
	enddo; 
	
EndProcedure 

Function getTrailers ( Car )
	
	s = "
	|select distinct Trailers.Trailer as Trailer, presentation ( Trailers.Trailer ) as TrailerPresentation
	|from Catalog.CarTypes.Trailers as Trailers
	|where Trailers.Ref in ( select CarType from Catalog.Cars where Ref = &Car )
	|";
	q = new Query ( s );
	q.SetParameter ( "Car", Car );
	return q.Execute ().Unload ();
	
EndFunction