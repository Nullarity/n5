// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	DocumentForm.SetCreator ( Object );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TenantOrderOnChange ( Item )
	
	setBonus ();
	
EndProcedure

&AtServer
Procedure setBonus ()
	
	s = "
	|select Agents.BonusBalance as Bonus
	|from AccumulationRegister.Agents.Balance ( , TenantOrder = &TenantOrder ) as Agents
	|";
	q = new Query ( s );
	q.SetParameter ( "TenantOrder", Object.TenantOrder );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		Object.Bonus = 0;
	else
		Object.Bonus = table [ 0 ].Bonus;
	endif; 
	
EndProcedure 
