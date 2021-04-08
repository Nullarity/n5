
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	filterByCompany ();
	filterByBound ();
	
EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	
EndProcedure 

&AtServer
Procedure filterByCompany ()
	
	Boundaries.Parameters.SetParameterValue ( "Company", Object.Company );
	
EndProcedure 

&AtServer
Procedure filterByBound ()
	
	date = ? ( Object.Bound = Date ( 1, 1, 1 ), Date ( 3999, 12, 31 ), EndOfDay ( Object.Bound ) );
	Boundaries.Parameters.SetParameterValue ( "Bound", date );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Restore ( Command )
	
	restoreSequence ();
	Items.Boundaries.Refresh ();
	
EndProcedure

&AtServer
Procedure restoreSequence ()
	
	SequenceCost.Restore ( Object.Bound, Object.Company );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure

&AtClient
Procedure BoundOnChange ( Item )
	
	filterByBound ();
		
EndProcedure
