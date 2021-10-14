
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not SessionParameters.TenantUse ) then
		Cancel = true;
		return;
	endif;
	if ( Forms.InsideMobileHomePage ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	InvoiceForm.SetPaidPercent ( ThisObject );
	InvoiceForm.SetShippedPercent ( ThisObject );
	UserTasks.InitList ( List );
	Options.SetAccuracy ( ThisObject, "GoodsQuantity, GoodsShipped, GoodsBalance", , false );
	setDepartment ();
	filterByStatus ();
	filterByDepartment ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Status show ( empty ( StatusFilter ) or StatusFilter = Enum.SalesOrderPoints.All );
	|Resolution show inlist ( StatusFilter, Enum.SalesOrderPoints.All, Enum.SalesOrderPoints.Finish );
	|Department show empty ( DepartmentFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setDepartment ()
	
	DepartmentFilter = Logins.Settings ( "Department" ).Department;
	
EndProcedure 

&AtServer
Procedure filterByStatus ()
	
	if ( StatusFilter.IsEmpty () ) then
		DC.ChangeFilter ( List, "Status", Enums.SalesOrderPoints.Finish, true, DataCompositionComparisonType.NotEqual );
	else
		DC.ChangeFilter ( List, "Status", StatusFilter, StatusFilter <> Enums.SalesOrderPoints.All );
	endif; 
	Appearance.Apply ( ThisObject, "StatusFilter" );
	
EndProcedure 

&AtServer
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "DepartmentFilter" );
	
EndProcedure 

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	filterByDepartment ();
	filterByStatus ();
	filterByWarehouse ();
	
EndProcedure

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageSalesOrderIsSaved () ) then
		if ( Parameter = SalesOrder ) then
			fillGoods ( SalesOrder, Goods );
		endif; 
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillGoods ( SalesOrder, Goods )
	
	table = getGoods ( SalesOrder );
	Collections.DeserializeFormTable ( Goods, table );
	
EndProcedure

&AtServerNoContext
Function getGoods ( val SalesOrder )
	
	s = "
	|select Balances.RowKey as RowKey, Balances.QuantityBalance as Balance
	|into Balances
	|from AccumulationRegister.SalesOrders.Balance ( , SalesOrder = &Ref ) as Balances
	|index by RowKey
	|;
	|select Goods.Description as Description, Goods.Package as Package, Goods.Quantity / Goods.Capacity as Quantity,
	|	case when Statuses.Status in (
	|			value ( Enum.SalesOrderPoints.Shipping ),
	|			value ( Enum.SalesOrderPoints.Invoicing ),
	|			value ( Enum.SalesOrderPoints.Finish )
	|		)
	|		then isnull ( Balances.Balance, 0 )
	|		else Goods.Quantity
	|	end / Goods.Capacity as Balance,
	|	( Goods.Quantity -
	|		case when Statuses.Status in (
	|				value ( Enum.SalesOrderPoints.Shipping ),
	|				value ( Enum.SalesOrderPoints.Invoicing ),
	|				value ( Enum.SalesOrderPoints.Finish )
	|			)
	|			then isnull ( Balances.Balance, 0 )
	|			else Goods.Quantity
	|		end ) / Goods.Capacity as Shipped,
	|	case when Goods.DeliveryDate <= &CurrentDate then true else false end as Expired,
	|	case
	|		when Balances.Balance is null
	|			and Statuses.Status in (
	|				value ( Enum.SalesOrderPoints.Shipping ),
	|				value ( Enum.SalesOrderPoints.Invoicing ),
	|				value ( Enum.SalesOrderPoints.Finish )
	|			)
	|			then true
	|		else false
	|	end as Complete,
	|	Goods.DeliveryDate as DeliveryDate, Goods.Unit as Unit
	|from (
	|		select Items.LineNumber as LineNumber, Items.RowKey as RowKey, Items.Item.Description as Description,
	|			Items.Package.Description as Package, Items.Quantity as Quantity, Items.Item.Unit.Code as Unit,
	|			case when Constants.Packages then Items.Capacity else 1 end as Capacity,
	|			case when Items.DeliveryDate = datetime ( 1, 1, 1 ) then Items.Ref.DeliveryDate else Items.DeliveryDate end as DeliveryDate
	|		from Document.SalesOrder.Items as Items
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
	|		from Document.SalesOrder.Services as Services
	|		where Services.Ref = &Ref
	|	) as Goods
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder as SalesOrders
	|	on SalesOrders.Ref = &Ref
	|	//
	|	// Balances
	|	//
	|	left join Balances as Balances
	|	on Balances.RowKey = Goods.RowKey
	|	//
	|	// SalesOrderStatuses
	|	//
	|	left join InformationRegister.SalesOrderStatuses as Statuses
	|	on Statuses.Document = &Ref
	|order by Goods.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", SalesOrder );
	q.SetParameter ( "CurrentDate", CurrentSessionDate () );
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
Procedure RefreshTables ( Command )
	
	updateTables ();
	
EndProcedure

&AtServer
Procedure updateTables ()
	
	Items.List.Refresh ();
	fillGoods ( SalesOrder, Goods );
	
EndProcedure

&AtClient
Procedure ListOnActivateRow ( Item )
	
	currentData = Items.List.CurrentData;
	if ( currentData = undefined ) then
		Goods.Clear ();
	else
		if ( currentData.Ref <> SalesOrder ) then
			SalesOrder = currentData.Ref;
			AttachIdleHandler ( "setGoods", 0.3, true );
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure setGoods ()
	
	fillGoods ( SalesOrder, Goods );
	
EndProcedure 

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure

// *****************************************
// *********** Goods

&AtClient
Procedure RefreshGoods ( Command )
	
	fillGoods ( SalesOrder, Goods );
	
EndProcedure

