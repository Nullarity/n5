// Open phones list
// Add new template and set it as default
// Close template and open again
// Check if Default checkbox is enabled
// Create a new Organization and check if that template is applying

Call ( "Common.Init" );
CloseAll ();

// Open phones list
Commando ( "e1cib/list/Catalog.Phones" );
list = With ( "Phone Numbers" );

// Add new template and set it as default
Click ( "#FormCreate" );
With ( "Phone Numbers (cr*" );
Set ( "#Mask", "9-9-9" );
Next ();
phone = Call ( "Common.GetID" );
Set ( "#Description", phone );
Click ( "#DefaultTemplate" );

// Close template
Click ( "#FormOK" );

// Check if Default checkbox is enabled
Click ( "#FormChange", list );
With ( phone + " *" );
Check ( "#DefaultTemplate", "Yes" );

// Create a new Organization and check if that template is applying
Commando ( "e1cib/data/Catalog.Organizations" );
With ( "Organizations (cr*" );
Set ( "#Phone", "123" );
Set ( "#Fax", "123" );
Next ();
Check ( "#Phone", "1-2-3" );
Check ( "#Fax", "1-2-3" );
Set ( "#Description", "Vendor " + phone );

// Check if there are no errors about wrong phone number
Click ( "#FormWrite" );
