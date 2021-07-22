// Create Phone Template
// Create Vendor
// Set phone template and put the value of phone
// Save & Close
// Open vendor again and check its phone number
// Put wrong number and try to save

Call ( "Common.Init" );
CloseAll ();

// Create Phone Template
Commando ( "e1cib/data/Catalog.Phones" );
With ( "Phone Numbers (cr*" );
template = "9-999-9999-999, ext.9999";
Set ( "#Mask", template );
Next ();
phone = Call ( "Common.GetID" );
Set ( "#Description", phone );
Click ( "#FormOK" );

// Create Vendor
vendor = "Vendor " + Call ( "Common.GetID" );
Commando ( "e1cib/list/Catalog.Organizations" );
list = With ( "Organizations" );
Click ( "#FormCreate" );

// Set phone template and put phone value
With ( "Organizations (cr*" );
Set ( "#Description", vendor );
Get ( "#Phone" ).StartChoosing ();
CurrentSource.ExecuteChoiceFromMenu ( phone );
Set ( "#Phone", "012345678901234" );

Click ( "#FormWriteAndClose" );

// Open again and check phone number
Click ( "#FormChange", list );
With ( vendor + " *" );
Check ( "#Phone", "0-123-4567-890, ext.1234" );

// Set wrong number and try to save
Set ( "#Phone", "1234567890" );
Click ( "#FormWrite" );

if ( FindMessages ( "* incorrect" ).Count () <> 1 ) then
	Stop ( "<The phone number is wrong> error messages must be shown one time" );
endif;

// Close
Close ();
Click ( "No", "1?:*" );
