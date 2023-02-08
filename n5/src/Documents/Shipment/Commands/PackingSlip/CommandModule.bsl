
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	if ( TypeOf ( List [ 0 ] ) = Type ( "DocumentRef.PickupOrder" ) ) then
		p.Objects = getShipments ( List );
	else
		p.Objects = List;
	endif;
	name = "PackingSlip";
	p.Key = name;
	p.Template = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure

&AtServer
Function getShipments ( val List )
	
	s = "
	|select PickedShipments.Shipment as Shipment
	|from InformationRegister.PickedShipments as PickedShipments
	|where PickupOrder in ( &List )
	|";
	q = new Query ( s );
	q.SetParameter ( "List", List );
	return q.Execute ().Unload ().UnloadColumn ( "Shipment" );
	
EndFunction 