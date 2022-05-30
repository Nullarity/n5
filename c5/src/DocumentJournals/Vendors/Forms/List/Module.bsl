// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedFilters ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|VendorFilter show empty ( FixedVendorFilter );
	|Vendor hide filled ( VendorFilter ) or filled ( FixedVendorFilter );
	|GroupQuickInfo show filled ( VendorFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Vendor", FixedVendorFilter );
	VendorFilter = FixedVendorFilter;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure VendorFilterOnChange ( Item )
	
	applyVendor ();
	
EndProcedure

&AtServer
Procedure applyVendor ()
	
	filterByVendor ();
	Appearance.Apply ( ThisObject, "VendorFilter" );
	
EndProcedure

&AtServer
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", VendorFilter, not VendorFilter.IsEmpty () );
	
EndProcedure 
