Procedure Init ( Env ) export
	
	Env.Insert ( "ItemDetails", new Structure ( "Item, Package, Feature, Series, Warehouse, Account" ) );
	Env.Insert ( "NewItemKeys", getTable () );
	Env.Insert ( "ItemDetailsRecordset", InformationRegisters.ItemDetails.CreateRecordSet () );
	
EndProcedure

Function getTable ()
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "Item", new TypeDescription ( "CatalogRef.Items" ) );
	columns.Add ( "Package", new TypeDescription ( "CatalogRef.Packages" ) );
	columns.Add ( "Feature", new TypeDescription ( "CatalogRef.Features" ) );
	columns.Add ( "Series", new TypeDescription ( "CatalogRef.Series" ) );
	columns.Add ( "Warehouse", new TypeDescription ( "CatalogRef.Warehouses" ) );
	columns.Add ( "Account", new TypeDescription ( "ChartOfAccountsRef.General" ) );
	columns.Add ( "ItemKey", new TypeDescription ( "CatalogRef.ItemKeys" ) );
	table.Indexes.Add ( "Item, Package, Feature, Series, Warehouse, Account" );
	return table;
	
EndFunction

Function GetKey ( Env, Item, Package = undefined, Feature = undefined, Series = undefined,
	Warehouse = undefined, Account = undefined ) export
	
	details = new Structure ( "Item, Package, Feature, Series, Warehouse, Account" );
	details.Item = Item;
	details.Package = ? ( Package = undefined, Catalogs.Packages.EmptyRef (), Package );
	details.Feature = ? ( Feature = undefined, Catalogs.Features.EmptyRef (), Feature );
	details.Series = ? ( Series = undefined, Catalogs.Series.EmptyRef (), Series );
	details.Warehouse = ? ( Warehouse = undefined, Catalogs.Warehouses.EmptyRef (), Warehouse );
	details.Account = ? ( Account = undefined, ChartsOfAccounts.General.EmptyRef (), Account );
	search = Env.NewItemKeys.FindRows ( details );
	if ( search.Count () = 0 ) then
		itemKey = newKey ( Env, details );
		row = Env.NewItemKeys.Add ();
		FillPropertyValues ( row, details );
		row.ItemKey = itemKey;
		return itemKey;
	else
		return search [ 0 ].ItemKey;
	endif; 
	
EndFunction

Function newKey ( Env, Details )
	
	item = Catalogs.ItemKeys.CreateItem ();
	item.Write ();
	record = Env.ItemDetailsRecordset.Add ();
	FillPropertyValues ( record, Details );
	record.ItemKey = item.Ref;
	return item.Ref;
	
EndFunction
 
Procedure Save ( Env ) export
	
	if ( Env.ItemDetailsRecordset.Count () > 0 ) then
		Env.ItemDetailsRecordset.Write ( false );
	endif; 
	
EndProcedure
