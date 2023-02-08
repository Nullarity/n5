Procedure MakeBarcodes ( Document ) export

	SetPrivilegedMode ( true );
	lockBarcodes ();
	for each row in getNew ( Document ) do
		r = InformationRegisters.Barcodes.CreateRecordManager ();
		r.Barcode = Goods.NewEAN13 ();
		r.Item = row.Item;
		r.Feature = row.Feature;
		r.Package = row.Package;
		r.Series = row.Series;
		r.Write ();
	enddo;
	
EndProcedure

Procedure lockBarcodes ()

	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Barcodes");
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();

EndProcedure

Function getNew ( Document )
	
	name = Metadata.FindByType ( TypeOf ( Document ) ).Name;
	s = "
	|select distinct Items.Item as Item, Items.Series as Series, Items.Package as Package, Items.Feature as Feature
	|from Document." + name + ".Items as Items
	|	//
	|	// Barcodes
	|	//
	|	left join InformationRegister.Barcodes as Barcodes
	|	on Barcodes.Series = Items.Series
	|	and Barcodes.Package = Items.Package
	|	and Barcodes.Item = Items.Item
	|	and Barcodes.Feature = Items.Feature
	|where Items.Ref = &Ref
	|and Barcodes.Barcode is null
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	return q.Execute ().Unload ();
	
EndFunction
