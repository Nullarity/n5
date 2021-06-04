StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description", "_Item: " + CurrentDate () );
p.Insert ( "CountPackages", false );
p.Insert ( "Service", false );
p.Insert ( "Product", false );
p.Insert ( "ItemType" );
p.Insert ( "CostMethod" );
p.Insert ( "Feature" );
p.Insert ( "UseCustomsGroup", false );
p.Insert ( "CustomsGroup" );
p.Insert ( "Unit" );
p.Insert ( "Capacity" );
if ( AppName = "c5" ) then
	p.Insert ( "VAT", "20%" );
	p.Insert ( "Social", false );
	p.Insert ( "OfficialCode" );
	p.Insert ( "Form", false );
endif;
return p;