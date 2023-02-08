
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedFilters ();
	filterWarehouses ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|VendorFilter show empty ( FixedVendorFilter );
	|WarehouseFilter show empty ( FixedWarehouseFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Vendor", FixedVendorFilter );
	Parameters.Filter.Property ( "Warehouse", FixedWarehouseFilter );
	VendorFilter = FixedVendorFilter;
	WarehouseFilter = FixedWarehouseFilter;
	
EndProcedure

&AtServer
Procedure filterWarehouses ()
	
	company = undefined;
	Parameters.Filter.Property ( "Company", company );
	if ( ValueIsFilled ( company ) ) then
		filter = new Array ();
		filter.Add ( new ChoiceParameter ( "Filter.Owner", company ) );
		Items.WarehouseFilter.ChoiceParameters = new FixedArray ( filter );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure VendorFilterOnChange ( Item )
	
	filterByVendor ();
	
EndProcedure

&AtClient
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", VendorFilter, not VendorFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure
