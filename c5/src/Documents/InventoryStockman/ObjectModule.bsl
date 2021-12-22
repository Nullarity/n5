
Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	SetPrivilegedMode ( true );
	makeBarcodes ();
	
EndProcedure

Procedure makeBarcodes ()

	for each row in getNew () do
		r = InformationRegisters.Штрихкоды.CreateRecordManager ();
		r.Код = ОбщегоНазначения.ПолучитьНовыйКодДляШтрихКода ();
		r.Lot = row.Lot;
		r.Владелец = row.Item;
		r.ЕдиницаИзмерения = row.Package;
		r.Штрихкод = Barcodes.NewEAN13 ();
		r.Write ();
	enddo;
	
EndProcedure

Function getNew ()
	
	s = "
	|select distinct Items.Item as Item, Items.Lot as Lot, Items.Package as Package
	|from Document.Inventory.Items as Items
	|	//
	|	// Barcodes
	|	//
	|	left join InformationRegister.Штрихкоды as Barcodes
	|	on Barcodes.Lot = Items.Lot
	|	and Barcodes.ЕдиницаИзмерения = Items.Package
	|	and Barcodes.Владелец = Items.Item
	|where Items.Ref = &Ref
	|and Barcodes.Код is null
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();
	
EndFunction
