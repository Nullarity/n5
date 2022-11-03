#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;
	
Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkPeriod () ) then
		Cancel = true;
		return;
	endif;
	if ( waybillAlreadyExists () ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkBoundary () ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkVerso () ) then
		Cancel = true;
	endif; 
	checkFuelMain ( CheckedAttributes );
	checkFuelHours ( CheckedAttributes );
	checkFuelEquipment ( CheckedAttributes );
	checkFuelOther ( CheckedAttributes );
	checkAccount ( CheckedAttributes );

EndProcedure

Function checkPeriod ()
	
	if ( Periods.Ok ( DateOpening, Date ) ) then
		return true;
	endif; 
	Output.IncorrectDateOpening ();
	return false;
	
EndFunction 

Function waybillAlreadyExists ()
	
	s = "
	|select Waybill.Ref as Ref
	|from Document.Waybill as Waybill
	|where Waybill.Ref.Date between &DateStart and &DateEnd
	|and Waybill.Ref <> &Ref
	|and Waybill.Car = &Car
	|and Waybill.Posted
	|";
	q = new Query ( s );
	q.SetParameter ( "DateStart", BegOfDay ( DateOpening ) );
	q.SetParameter ( "DateEnd", EndOfDay ( Date ) );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Car", Car );
	table = q.Execute ().Unload ();
	if ( table.Count () > 0 ) then
		for each row in table do
			p = new Structure ( "DateStart, DateEnd, Car, Document", Conversion.DateToString ( DateOpening ), Conversion.DateToString ( Date ), Car, row.Ref );
			Output.WrongWaybillPeriod ( p, , row.Ref );
		enddo;
		return true;
	endif;
	return false;
	
EndFunction 

Function checkBoundary ()
	
	lastIndex = Verso.Count () - 1;
	if ( lastIndex < 0 ) then
		return true;
	endif; 
	if ( BegOfDay ( Verso [ 0 ].DateStart ) < DateOpening ) then
		Output.BackSideIncorrectDateStart ( , Output.Row ( "BackSide", 1, "DateStart" ) );
		return false;
	endif; 
	if ( Verso [ lastIndex ].DateEnd > Date ) then
		Output.BackSideIncorrectDateEnd ( , Output.Row ( "BackSide", lastIndex + 1, "DateEnd" ) );
		return false;
	endif; 
	return true;
	
EndFunction 

Function checkVerso ()

	error = false;
	versoPresentation = Metadata.Documents.Waybill.TabularSections.Verso.Presentation ();
	for each row in Verso do
		if ( row.DateStart > row.DateEnd ) then
			p = new Structure ( "Table, LineNumber", versoPresentation, row.LineNumber );
			Output.WorkSequenceIncorrect ( p, Output.Row ( "Work", row.LineNumber, "DateStart" ) );
			error = true;
		endif; 
	enddo;
	return not error;
	
EndFunction 

Procedure checkFuelMain ( CheckedAttributes )
	
	if ( ExpenseOdometer <> 0 ) then
		CheckedAttributes.Add ( "FuelMain" );
	endif; 
	
EndProcedure 

Procedure checkFuelHours ( CheckedAttributes )
	
	if ( ExpenseEngineMax <> 0
		or ExpenseEngineAvg <> 0
		or ExpenseEngineMin <> 0
		or EngineHoursMax <> 0
		or EngineHoursAvg <> 0
		or EngineHoursMin <> 0 ) then
		CheckedAttributes.Add ( "FuelHours" );
	endif; 
	
EndProcedure 

Procedure checkFuelEquipment ( CheckedAttributes )
	
	if ( ExpenseEquipment <> 0
		or EquipmentWorkTime <> 0 ) then
		CheckedAttributes.Add ( "FuelEquipment" );
	endif; 
	
EndProcedure 

Procedure checkFuelOther ( CheckedAttributes )
	
	if ( OtherFuelExpense <> 0 ) then
		CheckedAttributes.Add ( "FuelOther" );
	endif; 
	
EndProcedure 

Procedure checkAccount ( CheckedAttributes )
	
	if ( FuelInventory ) then
		CheckedAttributes.Add ( "Account" );
	endif; 
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not Documents.Waybill.Post ( env );
	
EndProcedure

#endif