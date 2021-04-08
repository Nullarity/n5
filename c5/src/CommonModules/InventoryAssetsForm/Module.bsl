&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		DocumentForm.Init ( object );
		fillNew ( Form );
	endif; 
	InventoryAssetsForm.SetLinks ( Form );
	Options.Company ( Form, object.Company );
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks
	|" );
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	parameters = Form.Parameters;
	if ( not parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	if ( object.Department.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Department" );
		object.Company = settings.Company;
		object.Department = settings.Department;
	else
		object.Company = DF.Pick ( object.Department, "Owner" );
	endif;
	
EndProcedure 

&AtServer
Procedure SetLinks ( Form ) export
	
	env = getEnv ( Form );
	sqlLinks ( env );
	if ( env.Selection.Count () = 0 ) then
		Form.ShowLinks = false;
	else
		env.Q.SetParameter ( "Ref", env.object.Ref );
		SQL.Perform ( env );
		setURLPanel ( env );
	endif;
	Appearance.Apply ( Form, "ShowLinks" );

EndProcedure 

&AtServer
Function getEnv ( Form )
	
	object = Form.Object;
	ref = object.Ref;
	env = new Structure ( "IsNew", ref.IsEmpty () );
	SQL.Init ( env );
	env.Insert ( "Form", Form );
	env.Insert ( "Object", Form.Object );
	env.Insert ( "FixedAssets", TypeOf ( ref ) = Type ( "DocumentRef.AssetsInventory" ) );
	return env;
	
EndFunction 

&AtServer
Procedure sqlLinks ( Env )
	
	if ( Env.IsNew ) then
		return;
	endif;
	selection = Env.Selection;
	meta = Metadata.Documents;
	if ( Env.FixedAssets ) then
		document = meta.AssetsWriteOff;
	else
		document = meta.IntangibleAssetsWriteOff;
	endif; 
	viewWriteOff = AccessRight ( "View", document );
	if ( viewWriteOff ) then
		s = "
		|// #AssetsWriteOff
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + document.Name + " as Documents
		|where Documents.Inventory = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif; 
	receiveItems = meta.ReceiveItems;
	viewReceiveItems = AccessRight ( "View", receiveItems );
	if ( viewReceiveItems ) then
		s = "
		|// #ReceiveItems
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.ReceiveItems as Documents
		|where Documents.Inventory = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif;  
	Env.Insert ( "ViewWriteOff", viewWriteOff );
	Env.Insert ( "WriteOffDocument", document );
	Env.Insert ( "ViewReceiveItems", viewReceiveItems );
	Env.Insert ( "ReceiveItemsDocument", receiveItems );
	
EndProcedure 

&AtServer
Procedure setURLPanel ( Env )
	
	parts = new Array ();
	if ( not Env.IsNew ) then
		if ( Env.ViewWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.AssetsWriteOff, Env.WriteOffDocument ) );
		endif;	
		if ( Env.ViewReceiveItems ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.ReceiveItems, Env.ReceiveItemsDocument ) );	
		endif; 
	endif; 
	s = URLPanel.Build ( parts );
	form = Env.Form;
	if ( s = undefined ) then
		form.ShowLinks = false;
	else
		form.ShowLinks = true;
		form.Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Form ) export
	
	object = Form.Object;
	Forms.DeleteLastRow ( object.Items, "Item" );
	InventoryAssetsForm.CalcTotals ( object );
	
EndProcedure

&AtClient
Procedure CalcTotals ( Object ) export
	
	Object.Amount = Object.Items.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure Fill ( Form ) export
	
	if ( Forms.Check ( Form, "Department, Company" ) ) then
		Output.UpdateInventory ( ThisObject, Form );
	endif; 
	
EndProcedure

&AtClient
Procedure UpdateInventory ( Answer, Form ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Form.FillTable ();
	
EndProcedure 

Procedure CalcDifference ( ItemsRow ) export
	
	ItemsRow.Difference = ItemsRow.Availability - ItemsRow.Balance;
	ItemsRow.AmountDifference = ItemsRow.Amount - ItemsRow.AmountBalance;
	
EndProcedure
