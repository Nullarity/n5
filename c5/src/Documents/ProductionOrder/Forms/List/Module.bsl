// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	Options.SetAccuracy ( ThisObject, "GoodsQuantity, GoodsShipped, GoodsBalance", , false );
		
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	filterByWorkshop ();
	filterByWarehouse ();
	
EndProcedure

&AtServer
Procedure filterByWorkshop ()
	
	DC.ChangeFilter ( List, "Workshop", WorkshopFilter, not WorkshopFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageProductionOrderIsSaved () ) then
		if ( Parameter = ProductionOrder ) then
			fillGoods ( ProductionOrder, Goods );
		endif; 
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillGoods ( ProductionOrder, Goods )
	
	table = getGoods ( ProductionOrder );
	Collections.DeserializeFormTable ( Goods, table );
	
EndProcedure 

&AtServerNoContext
Function getGoods ( val ProductionOrder )
	
	s = "
	|select Balances.RowKey as RowKey, sum ( Balances.QuantityBalance ) as Balance
	|into Balances
	|from AccumulationRegister.ProductionOrders.Balance ( , ProductionOrder = &Ref ) as Balances
	|group by Balances.RowKey
	|having sum ( Balances.QuantityBalance ) > 0
	|index by RowKey
	|;
	|select Goods.Description as Description, Goods.Package as Package, Goods.Quantity / Goods.Capacity as Quantity,
	|	case when ProductionOrders.Posted then isnull ( Balances.Balance, 0 ) else Goods.Quantity end / Goods.Capacity as Balance,
	|	( Goods.Quantity -
	|		case when ProductionOrders.Posted then isnull ( Balances.Balance, 0 ) else Goods.Quantity end ) / Goods.Capacity as Shipped,
	|	case when Goods.DeliveryDate <= &CurrentDate then true else false end as Expired,
	|	case when Balances.Balance is null and ProductionOrders.Posted then true else false end as Complete,
	|	Goods.DeliveryDate as DeliveryDate, Goods.Unit as Unit
	|from (
	|		select Items.LineNumber as LineNumber, Items.RowKey as RowKey, Items.Item.Description as Description,
	|			Items.Package.Description as Package, Items.Quantity as Quantity, Items.Item.Unit.Code as Unit,
	|			case when Constants.Packages then Items.Capacity else 1 end as Capacity,
	|			case when Items.DeliveryDate = datetime ( 1, 1, 1 ) then Items.Ref.DeliveryDate else Items.DeliveryDate end as DeliveryDate
	|		from Document.ProductionOrder.Items as Items
	|			//
	|			// Constants
	|			//
	|			left join Constants as Constants
	|			on true
	|		where Items.Ref = &Ref
	|		union all
	|		select Services.LineNumber, Services.RowKey, Services.Description, Services.Item.Unit.Code,
	|			Services.Quantity, Services.Item.Unit.Code, 1,
	|			case when Services.DeliveryDate = datetime ( 1, 1, 1 ) then Services.Ref.DeliveryDate else Services.DeliveryDate end
	|		from Document.ProductionOrder.Services as Services
	|		where Services.Ref = &Ref
	|	) as Goods
	|	//
	|	// ProductionOrders
	|	//
	|	join Document.ProductionOrder as ProductionOrders
	|	on ProductionOrders.Ref = &Ref
	|	//
	|	// Balances
	|	//
	|	left join Balances as Balances
	|	on Balances.RowKey = Goods.RowKey
	|order by Goods.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", ProductionOrder );
	q.SetParameter ( "CurrentDate", CurrentSessionDate () );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return CollectionsSrv.Serialize ( table );
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure WorkshopFilterOnChange ( Item )
	
	applyWorkshop ();
	
EndProcedure

&AtServer
Procedure applyWorkshop ()
	
	if ( not WorkshopFilter.IsEmpty () ) then
		company = DF.Pick ( WorkshopFilter, "Owner" );
		if ( company <> DF.Pick ( WarehouseFilter, "Owner" ) ) then
			WarehouseFilter = undefined;
			filterByWarehouse ();
		endif;
	endif;
	filterByWorkshop ();
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	applyWarehouse ();
	
EndProcedure

&AtServer
Procedure applyWarehouse ()
	
	if ( not WarehouseFilter.IsEmpty () ) then
		company = DF.Pick ( WarehouseFilter, "Owner" );
		if ( company <> DF.Pick ( WorkshopFilter, "Owner" ) ) then
			WorkshopFilter = undefined;
			filterByWorkshop ();
		endif;
	endif;
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
		if ( currentData.Ref <> ProductionOrder ) then
			ProductionOrder = currentData.Ref;
			AttachIdleHandler ( "setGoods", 0.3, true );
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure setGoods ()
	
	fillGoods ( ProductionOrder, Goods );
	
EndProcedure 

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
