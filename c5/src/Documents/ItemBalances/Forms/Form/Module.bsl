&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.SetCreator ( Object );
		if ( Parameters.CopyingValue.IsEmpty () ) then
			BalancesForm.CheckParameters ( ThisObject );
		else
			BalancesForm.FixDate ( ThisObject );
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantity, ItemsTotalQuantityPkg", false );

EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	Object.Amount = Object.Items.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	calcAmount ( row );
	calcTotals ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcAmount ( Row )
	
	Row.Amount = Row.Cost * Row.QuantityPkg;
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	data = getItemData ( ItemsRow.Item );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Item )
	
	data = DF.Values ( Item, "Package, Package.Capacity as Capacity" );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	calcAmount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsCostOnChange ( Item )
	
	calcAmount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	calcCost ( ItemsRow );
	
EndProcedure

&AtClient
Procedure calcCost ( Row )
	
	Row.Cost = ? ( Row.QuantityPkg = 0, 0, Row.Amount / Row.QuantityPkg );
	
EndProcedure 

&AtClient
Procedure ItemsRangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	choose ( Item );
	
EndProcedure

&AtClient
Procedure choose ( Item )
	
	filter = new Structure ();
	filter.Insert ( "Date", Object.Date - 2 );
	filter.Insert ( "Item", ItemsRow.Item );
	filter.Insert ( "Feature", ItemsRow.Feature );
	filter.Insert ( "Series", ItemsRow.Series );
	filter.Insert ( "Package", ItemsRow.Package );
	filter.Insert ( "Capacity", ItemsRow.Capacity );
	filter.Insert ( "Account", Object.Account );
	filter.Insert ( "Company", Object.Company );
	OpenForm ( "Catalog.Ranges.Form.New", new Structure ( "Filter", filter ), Item );
	
EndProcedure
