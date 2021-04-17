Run ( "Attach" );
lib = new ( "AddIn.Core.Root" );
q = "
|// ^Table
|select * WHERE NULL = &P
|;
|// $Index
|select * WHERE NULL = &P
|;
|select 1
|where true
|;
|// ~Fields
|select * WHERE NULL = &P
|";
result = lib.QueryTables ( q );
result = Conversion.FromJSon ( result );
error = result [ 0 ].Name <> "Table"
	or result [ 1 ].Name <> "Index"
	or result [ 2 ].Name <> "Fields";
if ( error  ) then
	Stop ( "Method <QueryTables ()> does not work properly" );
endif;
