// Test Encode and Decode methods

Run ( "Attach" );
lib = new ( "AddIn.Core.Root" );
source = "test";
encoded = lib.Encode ( source, "key" );
if ( encoded = "test" ) then
	Stop ( "Method <Encode ()> does not work properly" );
endif;
if ( source <> lib.Decode ( encoded, "key" ) ) then
	Stop ( "Method <Decode ()> does not work properly" );
endif;
