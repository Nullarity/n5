// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	delivery = Parameters.Delivery;
	Receiver = delivery.To;
	Subject = delivery.Subject;
	TabDoc = GetFromTempStorage ( delivery.TableAddress );
	FileName = delivery.TableDescription;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Send ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	sendEmail ();
	Close ();
	
EndProcedure

&AtServer
Procedure sendEmail ()
	
	p = new Structure ( "Receiver, Subject, Spreadsheet, FileName",
		Receiver, Subject, TabDoc, FileName );
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "PrintFormMailing.Send", args, , , TesterCache.Testing () );
	
EndProcedure