// Create a new virtual range
// Set Type = Invoice Records and check fields
// Set Type = Invoices Online and check fields again

Call ( "Common.Init" );
CloseAll ();

prefix = Right(Call("Common.GetID"), 5);

Commando("e1cib/list/Catalog.Ranges");
Click("#FormCreate");
With();

Set ( "#Type", "Invoice Records" );
Next();
testing = "#Prefix, #Start, #Finish, #Total";
CheckState ( testing, "Visible" );

Set ( "#Type", "Invoices Online" );
Next();
Set ( "#Length", 9 );
CheckState ( testing, "Visible", false );

Click("#WriteAndClose");
CheckErrors ();

With (); // Enroll Range
Click ( "#FormWriteAndClose" );
CheckErrors ();

Disconnect();