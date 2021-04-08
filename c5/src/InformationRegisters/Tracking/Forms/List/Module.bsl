&AtClient
var TableRow;
&AtClient
var OldRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	WebClient = Environment.WebClient ();
	fixUser ();
	defaultZoom ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|UserFilter show not FixedUser
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fixUser ()
	
	UserFilter = Parameters.User;
	FixedUser = not UserFilter.IsEmpty ();
	if ( FixedUser ) then
		filterByUser ();
	endif; 
	
EndProcedure 

&AtServer
Procedure filterByUser ()
	
	DC.ChangeFilter ( List, "Application.User", UserFilter, not UserFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure defaultZoom ()
	
	Zoom = 15;
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
EndProcedure

&AtClient
Procedure PeriodFilterOnChange ( Item )
	
	filterByPeriod ();
	
EndProcedure

&AtServer
Procedure filterByPeriod ()
	
	DC.DeleteFilter ( List, "Date" );
	empty = Date ( 1, 1, 1 );
	date = PeriodFilter.StartDate;
	if ( date <> empty ) then
		DC.AddFilter ( List, "Date", date, DataCompositionComparisonType.GreaterOrEqual );
	endif; 
	date = PeriodFilter.EndDate;
	if ( date <> empty ) then
		DC.AddFilter ( List, "Date", date, DataCompositionComparisonType.LessOrEqual );
	endif; 
	
EndProcedure 

&AtClient
Procedure ZoomOnChange ( Item )
	
	GoogleMaps.SetZoom ( ThisObject, Items.GoogleMap, Zoom );
	
EndProcedure

&AtClient
Procedure UpdateMap () export
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	GoogleMap = GoogleMaps.ByLocation ( TableRow.Latitude, TableRow.Longitude, Zoom );
	
EndProcedure 

&AtClient
Procedure ZoomClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	defaultZoom ();
	GoogleMaps.SetZoom ( ThisObject, Items.GoogleMap, Zoom );
	
EndProcedure

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	if ( TableRow = undefined
		or TableRow.Error ) then
		return;
	elsif ( OldRow <> undefined
		and OldRow.Date = TableRow.Date
		and OldRow.Application = TableRow.Application ) then
		return;
	endif; 
	OldRow = TableRow;
	AttachIdleHandler ( "setLocation", 0.1, true );
	
EndProcedure

&AtClient
Procedure setLocation () export
	
	GoogleMaps.SetLocation ( ThisObject, Items.GoogleMap, TableRow.Latitude, TableRow.Longitude, Zoom );
	
EndProcedure 