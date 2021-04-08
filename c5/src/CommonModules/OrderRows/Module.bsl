Procedure ResetOrder ( TableRow ) export
	
	if ( TableRow.Property ( "Reservation" ) and TableRow.Reservation <> PredefinedValue ( "Enum.Reservation.PurchaseOrder" ) )
		or ( TableRow.Property ( "Provision" ) and TableRow.Provision <> PredefinedValue ( "Enum.Provision.Directly" ) ) then
		TableRow.DocumentOrder = undefined;
		TableRow.DocumentOrderRowKey = undefined;
	endif; 
	
EndProcedure

Procedure ResetPerformer ( TableRow ) export
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	performer = TableRow.Performer;
	if ( performer.IsEmpty () )
		or ( performer = PredefinedValue ( "Enum.Performers.Department" )
			and TableRow.Department.IsEmpty () ) then
		TableRow.Performer = PredefinedValue ( "Enum.Performers.None" );
	endif; 
	
EndProcedure

Procedure ResetDepartment ( TableRow ) export
	
	if ( TableRow.Performer <> PredefinedValue ( "Enum.Performers.Department" ) ) then
		TableRow.Department = undefined;
	endif; 
	
EndProcedure

Procedure ResetStock ( TableRow ) export
	
	if ( TableRow.Reservation <> PredefinedValue ( "Enum.Reservation.Warehouse" ) ) then
		TableRow.Stock = undefined;
	endif;
	
EndProcedure

Procedure ResetReservation ( TableRow, Default ) export
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	reservation = TableRow.Reservation;
	if ( reservation.IsEmpty () )
		or ( reservation = PredefinedValue ( "Enum.Reservation.Warehouse" )
			and TableRow.Stock.IsEmpty () )
		or ( reservation = PredefinedValue ( "Enum.Reservation.PurchaseOrder" )
			and TableRow.DocumentOrder = undefined ) then
		TableRow.Reservation = Default;
	endif; 
	
EndProcedure

Procedure ResetProvision ( TableRow ) export
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	provision = TableRow.Provision;
	if ( provision.IsEmpty () )
		or ( provision = PredefinedValue ( "Enum.Provision.Directly" )
			and not ValueIsFilled ( TableRow.DocumentOrder ) ) then
		TableRow.Provision = PredefinedValue ( "Enum.Provision.Free" );
	endif; 
	
EndProcedure
