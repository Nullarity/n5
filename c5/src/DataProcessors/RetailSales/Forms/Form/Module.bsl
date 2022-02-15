// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();

EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Company, Warehouse, Department, PaymentLocation" );
	Object.Company = settings.Company;
	Object.Warehouse = settings.Warehouse;
	Object.Department = settings.Department;
	Object.Location = settings.PaymentLocation;
	Object.Day = BegOfDay ( CurrentSessionDate () );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( CheckFilling () ) then
		NotifyChoice ( data () );
	endif;

EndProcedure

&AtClient
Function data ()
	
	result = new Structure ();
	result.Insert ( "Company", Object.Company );
	result.Insert ( "Day", Object.Day );
	result.Insert ( "Department", Object.Department );
	result.Insert ( "Location", Object.Location );
	result.Insert ( "Method", Object.Method );
	result.Insert ( "Warehouse", Object.Warehouse );
	result.Insert ( "Memo", Object.Memo );
	return result;

EndFunction