// Open settings
// Set Country
// Create a Payment Address and check if country and zip code are filled correctly

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/CommonForm.Settings" );
With();

Put ( "#Country", "Moldova" );
Activate("#PaymentAddress").Create ();
With();

Check("#ZIPFormat", "Moldova");
