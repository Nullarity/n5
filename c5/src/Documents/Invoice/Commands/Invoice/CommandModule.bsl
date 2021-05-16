
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	if ( TypeOf ( List [ 0 ] ) = Type ( "DocumentRef.PickupOrder" ) ) then
		invoices = getInvoices ( List );
		if ( invoices.Count () = 0 ) then
			Output.InvoicesNotReady ();
			return;
		endif; 
		p.Objects = invoices;
	else
		p.Objects = List;
	endif;
	name = "Invoice";
	p.Key = name;
	p.Name = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure

&AtServer
Function getInvoices ( val List )
	
	s = "
	|select PickedShipments.Shipment as Shipment
	|into Shipments
	|from InformationRegister.PickedShipments as PickedShipments
	|where PickupOrder in ( &List )
	|index by Shipment
	|;
	|select Invoices.Ref as Invoice
	|from Document.Invoice as Invoices
	|where Invoices.Shipment in ( select Shipment from Shipments )
	|and not Invoices.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "List", List );
	return q.Execute ().Unload ().UnloadColumn ( "Invoice" );
	
EndFunction 
