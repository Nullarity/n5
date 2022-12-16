
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
Procedure Reset ( Command )
	
	resetSequence ();
	
EndProcedure

&AtServer
Procedure resetSequence ()
	
	q = new Query ( "select Item from Sequence.Cost where Company = &Company" );
	company = Object.Company;
	q.SetParameter ( "Company", company );
	selection = q.Execute ().Select ();
	while ( selection.Next () ) do
		Sequences.Cost.SetBound ( CurrentSessionDate (),
			new Structure ( "Company, Item", company, selection.Item ) );
	enddo;
	
EndProcedure

&AtClient
Procedure Restore ( Command )
	
	run ();
	Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Restored", ThisObject ), true );

EndProcedure

&AtServer
Procedure run () 

	p = DataProcessors.Cost.GetParams ();
	p.Bound = Object.Bound;
	p.Company = Object.Company;
	args = new Array ();
	args.Add ( "Cost" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );

EndProcedure

&AtClient
Procedure Restored ( Result, Params ) export
	
	if ( not Result ) then
		return;
	endif;
	Items.Boundaries.Refresh ();

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure

&AtClient
Procedure BoundOnChange ( Item )
	
	filterByBound ();
		
EndProcedure
