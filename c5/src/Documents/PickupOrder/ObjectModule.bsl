#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var CurrentStatus;
var Command;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	defineCommand ();
	if ( DeletionMark ) then
		if ( not canRemove () ) then
			Cancel = true;
		endif; 
		removeRelations ();
		return;
	else
		if ( isRemoved () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	if ( Command = undefined ) then
		return;
	elsif ( Command = Enums.Actions.StartPicking ) then
		setShipments ( Enums.ShipmentPoints.Picking );
		setStatus ( Enums.ShipmentPoints.Picking );
	elsif ( Command = Enums.Actions.CompletePicking ) then
		if ( completeShipments () ) then
			setStatus ( Enums.ShipmentPoints.Finish );
		else
			Cancel = true;
		endif; 
	endif; 
	
EndProcedure

Procedure defineCommand ()
	
	if ( Action.IsEmpty () ) then
		Command = undefined;
	else
		Command = Action;
		Action = undefined;
	endif; 
	
EndProcedure 

Function canRemove ()
	
	if ( IsInRole ( "Administrator" ) ) then
		return true;
	endif; 
	CurrentStatus = InformationRegisters.PickupOrderStatuses.Get ( new Structure ( "Document", Ref ) ).Status;
	if ( CurrentStatus <> Enums.ShipmentPoints.New ) then
		Output.OrderCannotBeChanged ();
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure removeRelations ()
	
	if ( CurrentStatus = Enums.ShipmentPoints.Finish ) then
		return;
	endif;
	clearPickedShipments ();
	setShipments ( Enums.ShipmentPoints.New );
	setStatus ( Enums.ShipmentPoints.Canceled );
	
EndProcedure 

Procedure clearPickedShipments ()
	
	table = getShipments ();
	for each shipment in table do
		r = InformationRegisters.PickedShipments.CreateRecordManager ();
		r.Shipment = shipment;
		r.Delete ();
	enddo; 
	
EndProcedure 

Function getShipments ()
	
	table = Shipments.Unload ( , "Shipment" ).UnloadColumn ( "Shipment" );
	Collections.Group ( table );
	return table;
	
EndFunction 

Procedure setShipments ( Status )
	
	table = getShipments ();
	for each shipment in table do
		setShipmentStatus ( shipment, Status );
	enddo; 
	
EndProcedure 

Procedure setShipmentStatus ( Document, Status )
	
	r = InformationRegisters.ShipmentStatuses.CreateRecordManager ();
	r.Document = Document;
	r.Status = Status;
	r.Write ();
	
EndProcedure 

Procedure setStatus ( Status )
	
	r = InformationRegisters.PickupOrderStatuses.CreateRecordManager ();
	r.Document = Ref;
	r.Status = Status;
	r.Write ();
	
EndProcedure 

Function isRemoved ()
	
	if ( IsNew () or IsInRole ( "Administrator" ) ) then
		return false;
	endif; 
	removed = DF.Pick ( Ref, "DeletionMark as DeletionMark" );
	if ( removed ) then
		Output.DocumentIsRemoved ();
		return true;
	endif; 
	return false;
	
EndFunction 

Function completeShipments ()
	
	table = getShipments ();
	for each shipment in table do
		obj = shipment.GetObject ();
		moveItems ( obj );
		if ( Documents.Shipment.CreateInvoice ( obj ) ) then
			Documents.Shipment.CreateBackOrder ( obj );
			setShipmentStatus ( shipment, Enums.ShipmentPoints.Finish );
		else
			return false;
		endif;
	enddo; 
	return true;
	
EndFunction

Procedure moveItems ( Shipment )
	
	recalculation = false;
	table = Shipment.Items.Unload ();
	rows = Shipments.FindRows ( new Structure ( "Shipment", Shipment.Ref ) );
	vatUse = Shipment.VATUse;
	for each row in rows do
		shipmentRow = table.Find ( row.RowKey, "RowKey" );
		FillPropertyValues ( shipmentRow, row );
		if ( shipmentRow.QuantityBack > 0 ) then
			Computations.Amount ( shipmentRow );
			Computations.Total ( shipmentRow, vatUse );
			recalculation = true;
		endif; 
	enddo; 
	Shipment.Items.Load ( table );
	if ( recalculation ) then
		InvoiceForm.CalcTotals ( Shipment );
		Shipment.Write ();
	endif; 
	
EndProcedure 

#endif