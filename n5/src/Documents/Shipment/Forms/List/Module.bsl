
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	filterByStatus ();
	filterByDepartment ();
	filterByWarehouse ();
	Options.SetAccuracy ( ThisObject, "GoodsQuantity", , false );
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Status show ( empty ( StatusFilter ) or StatusFilter = Enum.ShipmentPoints.All );
	|Resolution show inlist ( StatusFilter, Enum.ShipmentPoints.All, Enum.ShipmentPoints.Finish );
	|Department show empty ( DepartmentFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Warehouse, Department" );
	DepartmentFilter = settings.Department;
	WarehouseFilter = settings.Warehouse;
	
EndProcedure 

&AtServer
Procedure filterByStatus ()
	
	if ( StatusFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, "Status", Enums.ShipmentPoints.Finish, true, DataCompositionComparisonType.NotEqual );
	else
		DC.ChangeFilter ( List, "Status", StatusFilter, StatusFilter <> Enums.ShipmentPoints.All );
	endif; 
	Appearance.Apply ( ThisObject, "StatusFilter" );
	
EndProcedure 

&AtServer
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "DepartmentFilter" );
	
EndProcedure 

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageShipmentIsSaved () ) then
		if ( Parameter = Shipment ) then
			fillGoods ( Shipment, Goods );
		endif; 
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillGoods ( Shipment, Goods )
	
	table = getGoods ( Shipment );
	Collections.DeserializeFormTable ( Goods, table );
	
EndProcedure 

&AtServerNoContext
Function getGoods ( val Shipment )
	
	s = "
	|select Goods.Description as Description, Goods.Package as Package,
	|	Goods.Quantity / Goods.Capacity as Quantity, Goods.Unit as Unit
	|from (
	|		select Items.LineNumber as LineNumber, Items.RowKey as RowKey, Items.Item.Description as Description,
	|			Items.Package.Description as Package, Items.Quantity as Quantity, Items.Item.Unit.Code as Unit,
	|			case when Constants.Packages then Items.Capacity else 1 end as Capacity
	|		from Document.Shipment.Items as Items
	|			//
	|			// Constants
	|			//
	|			left join Constants as Constants
	|			on true
	|		where Items.Ref = &Ref
	|		union all
	|		select Services.LineNumber, Services.RowKey, Services.Description, Services.Item.Unit.Code,
	|			Services.Quantity, Services.Item.Unit.Code, 1
	|		from Document.Shipment.Services as Services
	|		where Services.Ref = &Ref
	|	) as Goods
	|order by Goods.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Shipment );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return CollectionsSrv.Serialize ( table );
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByCustomer ();
	
EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();

EndProcedure

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure ItemFilterOnChange ( Item )
	
	filterByItem ();
	
EndProcedure

&AtServer
Procedure filterByItem ()
	
	param = DC.GetParameter ( List.SettingsComposer, "Item" );
	if ( ItemFilter.IsEmpty () ) then
		param.Use = false;
	else
		param.Use = true;
		param.Value = ItemFilter;
	endif; 
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListOnActivateRow ( Item )
	
	currentData = Items.List.CurrentData;
	if ( currentData = undefined ) then
		Goods.Clear ();
	else
		if ( currentData.Ref <> Shipment ) then
			Shipment = currentData.Ref;
			AttachIdleHandler ( "setGoods", 0.3, true );
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure setGoods ()
	
	fillGoods ( Shipment, Goods );
	
EndProcedure 
