// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Repository show empty ( RepositoryFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure RepositoryFilterOnChange ( Item )
	
	applyRepository ();
	
EndProcedure

&AtClient
Procedure applyRepository ()
	
	DC.ChangeFilter ( List, "Repository", RepositoryFilter, not RepositoryFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "RepositoryFilter" );
	
EndProcedure

&AtClient
Procedure Load ( Command )

	OpenForm ( "DataProcessor.LoadIssues.Form" );

EndProcedure
