// Test Method: SetClientID ()

Run ( "Attach" );
lib = new ( "AddIn.Core.Root" );
original = "#ЯблокуНегдеУпасть#";
lib.SetClientID ( original );
code = lib.GetClientID ();
if ( code <> original ) then
	Stop ( "GetClientID () returns " + code + ", but right value should be " + original );
endif;
