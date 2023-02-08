// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	document = Metadata.FindByType ( TypeOf ( Parameters.Document ) ).Presentation ();
	Items.Label.Title = Output.FormatStr ( Items.Label.Title, new Structure ( "Document", document ) );
	Date = Parameters.Date;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )

	save ();
	Close ();
	
EndProcedure

&AtServer
Procedure save ()
	
	id = Enum.SettingsPinnedDate ();
	class = TypeOf ( Parameters.Document );
	if ( Variant = 1
		or Date = Date ( 1, 1, 1 ) ) then
		LoginsSrv.DeleteSettings ( id, class );
	else
		LoginsSrv.SaveSettings ( id, class, Date );
	endif; 
	
EndProcedure 
