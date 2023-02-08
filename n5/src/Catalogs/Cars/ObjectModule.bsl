
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkCarAndAsset () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkCarAndAsset ()
	
	s = "
	|select top 1 presentation ( Cars.Warehouse ) as Warehouse, presentation ( Cars.FixedAsset ) as FixedAsset, presentation ( Cars.Ref ) as Car
	|from Catalog.Cars as Cars
	|where Cars.Ref <> &Ref
	|and ( Cars.Warehouse = &Warehouse
	|or ( Cars.FixedAsset = &FixedAsset and Cars.FixedAsset <> value ( Catalog.FixedAssets.EmptyRef ) ) )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Warehouse", Warehouse );
	q.SetParameter ( "FixedAsset", FixedAsset );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return true;
	endif; 
	p = new Structure ( "Car, Warehouse, FixedAsset" );
	FillPropertyValues ( p, table [ 0 ] );
	Output.CarAccountingDataError ( p );
	return false;
	
EndFunction 
