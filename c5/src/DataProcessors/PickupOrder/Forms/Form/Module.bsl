&AtClient
var ShipmentsRow;
&AtServer
var SelectedShipments;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	init ();
	fill ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Warehouse = Parameters.Warehouse;
	
EndProcedure 

&AtServer
Procedure init ()
	
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Required = CurrentSessionDate ();
	
EndProcedure 

&AtServer
Procedure fill ()
	
	Object.Shipments.Clear ();
	if ( Object.Warehouse.IsEmpty () ) then
		return;
	endif; 
	table = getShipments ();
	for each row in table do
		newRow = Object.Shipments.Add ();
		FillPropertyValues ( newRow, row );
		newRow.Shipment = row.Number + " " + row.Date;
	enddo; 
	
EndProcedure 

&AtServer
Function getShipments ()
	
	s = "
	|select allowed Shipments.Ref as ShipmentRef, Shipments.DeliveryDate as DeliveryDate, true as Use,
	|	Shipments.Date as Date, Shipments.Number as Number,
	|	Shipments.Customer.Description as Customer, Shipments.Customer.ShippingAddress.Presentation as Address
	|from Document.Shipment as Shipments
	|	//
	|	// PickedShipments
	|	//
	|	left join InformationRegister.PickedShipments as PickedShipments
	|	on PickedShipments.Shipment = Shipments.Ref
	|	//
	|	// Statuses
	|	//
	|	join InformationRegister.ShipmentStatuses as Statuses
	|	on Statuses.Document = Shipments.Ref
	|	and Statuses.Status = value ( Enum.ShipmentPoints.New )
	|and Shipments.Warehouse = &Warehouse
	|and not Shipments.DeletionMark
	|and PickedShipments.PickupOrder is null
	|order by DeliveryDate, Shipments.Customer.ShippingAddress.Description, Customer
	|";
	q = new Query ( s );
	q.SetParameter ( "Warehouse", Object.Warehouse );
	return q.Execute ().Unload ();
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure Create ( Command )
	
	Output.CreatePickupOrderConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure CreatePickupOrderConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( not CheckFilling () ) then
		return;
	endif; 
	if ( not shipmentsSelected () ) then
		return;
	endif; 
	pickupOrder = createOrder ();
	NotifyWritingNew ( pickupOrder );
	Close ();
	
EndProcedure 

&AtClient
Function shipmentsSelected ()
	
	for each row in Object.Shipments do
		if ( row.Use ) then
			return true;
		endif; 
	enddo; 
	Output.ShipmentNotSelected ();
	return false;
	
EndFunction 

&AtServer
Function createOrder ()
	
	BeginTransaction ();
	getSelectedShipments ();
	order = newOrder ();
	makePicked ( order );
	CommitTransaction ();
	return order;
	
EndFunction 

&AtServer
Procedure getSelectedShipments ()
	
	SelectedShipments = new Array ();
	for each row in Object.Shipments do
		if ( row.Use ) then
			SelectedShipments.Add ( row.ShipmentRef );
		endif; 
	enddo; 
	Collections.Group ( SelectedShipments );

EndProcedure

&AtServer
Function newOrder ()
	
	obj = Documents.PickupOrder.CreateDocument ();
	obj.Company = Object.Company;
	obj.Memo = Object.Memo;
	obj.Required = Object.Required;
	obj.Warehouse = Object.Warehouse;
	obj.Creator = SessionParameters.User;
	obj.Date = CurrentSessionDate ();
	table = getItems ();
	obj.Shipments.Load ( table );
	table.GroupBy ( "Capacity, Feature, Item, Package",
	"Quantity, QuantityBack, QuantityPkg, QuantityPkgBack, QuantityPkgPlan, QuantityPlan" );
	obj.Items.Load ( table );
	obj.Write ();
	r = InformationRegisters.PickupOrderStatuses.CreateRecordManager ();
	r.Document = obj.Ref;
	r.Status = Enums.ShipmentPoints.New;
	r.Write ();
	return obj.Ref;
	
EndFunction 

&AtServer
Function getItems ()
	
	s = "
	|select Items.*, Items.Ref as Shipment
	|from Document.Shipment.Items as Items
	|where Items.Ref in ( &Shipments )
	|order by Items.Ref.Customer, Items.Ref, Items.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Shipments", SelectedShipments );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure makePicked ( PickupOrder )
	
	for each shipment in SelectedShipments do
		r = InformationRegisters.PickedShipments.CreateRecordManager ();
		r.Shipment = shipment;
		r.PickupOrder = PickupOrder;
		r.Write ();
	enddo; 
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	Object.Shipments.Clear ();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange ( Item )
	
	fill ();
	
EndProcedure

// *****************************************
// *********** Table Shipments

&AtClient
Procedure MarkAll ( Command )
	
	Forms.MarkRows ( Object.Shipments, true );

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	Forms.MarkRows ( Object.Shipments, false );

EndProcedure

&AtClient
Procedure ShipmentsOnActivateRow ( Item )
	
	ShipmentsRow = Items.Shipments.CurrentData;
	
EndProcedure

&AtClient
Procedure ShipmentsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ShipmentsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ShipmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "ShipmentsShipment" ) then
		StandardProcessing = false;
		ShowValue ( , ShipmentsRow.ShipmentRef );
	endif; 
	
EndProcedure
