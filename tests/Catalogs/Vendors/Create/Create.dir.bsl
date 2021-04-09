Commando("e1cib/command/Catalog.Organizations.Create");
Set("Name", _.Name);
if ( Fetch ( "#Vendor" ) = "No" ) then
	Click ( "#Vendor" );
endif;
Click ( "#FormWriteAndClose" );
