
Procedure Fill ( Form ) export
	
	object = Form.Object;
	table = getTable ( object );
	itemsTable = object.Items;
	search = new Structure ( "Item" );
	for each row in table do
		FillPropertyValues ( search, row );
		foundRows = itemsTable.FindRows ( search );
		found = foundRows.Count () > 0;
		if ( found ) then
			itemsRow = foundRows [ 0 ];
		else
			itemsRow = itemsTable.Add ();
			FillPropertyValues ( itemsRow, row );
		endif; 
		itemsRow.Balance = row.Availability;
		itemsRow.AmountBalance = row.Amount;
		if ( found ) then
			InventoryAssetsForm.CalcDifference ( itemsRow );
		endif; 
	enddo; 
	
EndProcedure 

Function getTable ( Object )
	
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.AssetsInventory" ) ) then
		register = "FixedAssetsLocation";
	else
		register = "IntangibleAssetsLocation";
	endif;
	s = "
	|// Items
	|select Location.Asset as Item, Location.Asset.Account as Account
	|into Items
	|from InformationRegister." + register + ".SliceLast ( &Date ) as Location
	|where Location.Department = &Department
	|";
	if ( not Object.Employee.IsEmpty () ) then
		s = s + "and Location.Employee = &Employee";
	endif; 
	s = s + "
	|;
	|select Items.Item as Item, Balances.AmountBalance as Amount, true as Availability
	|from Items as Items
	|	//
	|	// Balances
	|	//
	|	left join AccountingRegister.General.Balance ( &Date, Account in ( select Account from Items ), ,
	|		ExtDimension1 in ( select Item from Items ) and Company = &Company ) as Balances
	|	on Balances.ExtDimension1 = Items.Item
	|	and Balances.Account = Items.Account
	|order by Item.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Department", Object.Department );
	q.SetParameter ( "Employee", Object.Employee );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	table = q.Execute ().Unload ();
	table.Indexes.Add ( "Item" );
	return table;
	
EndFunction 
