// Open settings
// Set Country
// Create a Payment Address and check if country and zip code are filled correctly

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/CommonForm.Settings" );
With();

Pick ( "#Country", "Canada" );
Activate("#PaymentAddress").Create ();
With();

Check("#ZIPFormat", "H7T-1V3 (Canada)");
