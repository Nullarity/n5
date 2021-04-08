// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setBook ();
	
EndProcedure

&AtServer
Procedure setBook ()
	
	Book = Parameters.Book;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Change ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	start ();
	Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Complete", ThisObject ) );
	
EndProcedure

&AtServer
Procedure start ()
	
	p = new Array ();
	p.Add ( Creator );
	p.Add ( Book );
	Jobs.Run ( "DocumentsCreator.Change", p, UUID );
	
EndProcedure 

&AtClient
Procedure Complete ( Result, Params ) export
	
	Output.DocumentsCreatorChanged ( ThisObject );
	
EndProcedure 

&AtClient
Procedure DocumentsCreatorChanged ( Params ) export
	
	NotifyChanged ( Type ( "DocumentRef.Document" ) );
	Close ();
	
EndProcedure 