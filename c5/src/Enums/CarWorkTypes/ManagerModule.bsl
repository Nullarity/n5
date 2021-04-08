
Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	if ( Parameters.Property ( "Car" ) ) then
		StandardProcessing = false;
		fillByCar ( ChoiceData, Parameters.Car );
	endif; 
	
EndProcedure

Procedure fillByCar ( ChoiceData, Car )
	
	ChoiceData = new ValueList ();
	table = getWorkTypes ( Car );
	for each row in table do
		ChoiceData.Add ( row.Work, row.WorkPresentation );
	enddo; 
	
EndProcedure 

Function getWorkTypes ( Car )
	
	s = "
	|select distinct WorkTypes.Work as Work, presentation ( WorkTypes.Work ) as WorkPresentation
	|from Catalog.CarTypes.WorkTypes as WorkTypes
	|where WorkTypes.Ref in ( select CarType from Catalog.Cars where Ref = &Car )
	|";
	q = new Query ( s );
	q.SetParameter ( "Car", Car );
	return q.Execute ().Unload ();
	
EndFunction