&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		DocumentForm.Init ( object );
		fillNew ( Form );
		Constraints.ShowAccess ( ThisObject );
	endif;
	StandardButtons.Arrange ( Form );
	
EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	parameters = Form.Parameters;
	if ( not parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	if ( object.Sender.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Department" );
		object.Company = settings.Company;
		object.Sender = settings.Department;
	else
		object.Company = DF.Pick ( object.Sender, "Owner" );
	endif;
	AssetsTransferForm.FillTable ( object );
	
EndProcedure 

&AtServer
Procedure FillTable ( Object ) export
	
	assets = Object.Items;
	if ( Object.Sender.IsEmpty ()
		or Object.Responsible.IsEmpty () ) then
		assets.Clear ();
	else
		table = getTable ( Object );
		assets.Load ( table );
	endif; 
	
EndProcedure 

&AtServer
Function getTable ( Object )
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.AssetsTransfer" ) ) then
		name = "FixedAssetsLocation";
	else
		name = "IntangibleAssetsLocation";
	endif; 
	s = "
	|select Location.Asset as Item, Location.Asset.Account as Account
	|into Items
	|from InformationRegister." + name + ".SliceLast ( &Date ) as Location
	|where Location.Department = &Department
	|and Location.Employee = &Employee
	|index by Item, Account
	|;
	|select Items.Item as Item
	|from Items as Items
	|	//
	|	// Balances
	|	//
	|	join AccountingRegister.General.Balance ( &Date, Account in ( select distinct Account from Items ), ,
	|		ExtDimension1 in ( select Item from Items ) and Company = &Company ) as Balances
	|	on Balances.ExtDimension1 = Items.Item
	|	and Balances.Account = Items.Account
	|where Balances.QuantityBalance > 0
	|order by Item.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Department", Object.Sender );
	q.SetParameter ( "Employee", Object.Responsible );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure Fill ( Form ) export
	
	if ( Forms.Check ( Form, "Sender, Company" ) ) then
		Forms.ClearTables ( Form.Object.Items, "ClearTableConfirmation", ThisObject, Form );
	endif; 
	
EndProcedure

&AtClient
Procedure ClearTableConfirmation ( Answer, Form ) export
	
	if ( Form.Object.Items.Count () > 0 ) then
		return;
	endif; 
	Form.FillTable ();
	
EndProcedure 
