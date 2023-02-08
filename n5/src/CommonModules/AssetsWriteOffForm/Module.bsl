&AtServer
Procedure OnReadAtServer ( Form, CurrentObject ) export
	
	InvoiceForm.SetLocalCurrency ( Form );
	readAccount ( Form );
	labelDims ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAccount ( Form )
	
	object = Form.Object;
	data = GeneralAccounts.GetData ( object.ExpenseAccount );
	Form.AccountData = data;
	Form.ExpensesLevel = data.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ( Form )
	
	items = Form.Items;
	i = 1;
	for each dim in Form.AccountData.Dims do
		Items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( Form );
		DocumentForm.Init ( object );
		base = Form.Parameters.Basis;
		if ( base = undefined ) then
			fillNew ( Form );
		else
			Form.Base = base;
			baseType = TypeOf ( base );
			if ( baseType = Type ( "DocumentRef.AssetsInventory" )
				or baseType = Type ( "DocumentRef.IntangibleAssetsInventory" ) ) then
				fillByInventory ( Form );
			endif;
			setCurrency ( Form );
		endif;
	endif; 
	setLinks ( Form );
	Options.Company ( Form, object.Company );
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	rules.Add ( "
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2;
	|ShowDetails press Object.Detail;
	|GrossAmount Amount VATUse show Object.ShowPrices;
	|Links show ShowLinks;
	|VAT show ( Object.VATUse > 0 and Object.ShowPrices );
	|ItemsExpenseAccount ItemsDim1 ItemsDim2 ItemsDim3 ItemsProduct ItemsProductFeature hide not Object.Detail;
	|ItemsAmount show Object.ShowPrices;
	|ItemsVATCode ItemsVAT ItemsTotal show ( Object.VATUse > 0 and Object.ShowPrices )
	|" );
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	if ( not Form.Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	settings = Logins.Settings ( "Company" );
	object.Company = settings.Company;
	setCurrency ( Form );
	
EndProcedure

&AtServer
Procedure setCurrency ( Form )
	
	Form.Object.Currency = Application.Currency ();
	AssetsWriteOffForm.ApplyCurrency ( Form );
	
EndProcedure

&AtServer
Procedure ApplyCurrency ( Form ) export
	
	object = Form.Object;
	rates = CurrenciesSrv.Get ( object.Currency );
	object.Rate = rates.Rate;
	object.Factor = rates.Factor;
	Appearance.Apply ( Form, "Object.Currency" );
	
EndProcedure 

&AtServer
Procedure fillByInventory ( Form )
	
	setEnv ( Form );
	sqlInventory ( Form );
	SQL.Perform ( Form.Env );
	headerByInventory ( Form );
	itemsByInventory ( Form );
	
EndProcedure

&AtServer
Procedure setEnv ( Form )
	
	SQL.Init ( Form.Env );
	env = Form.Env;
	env.Q.SetParameter ( "Base", Form.Base );
	
EndProcedure

&AtServer
Procedure sqlInventory ( Form )
	
	if ( TypeOf ( Form.Object.Ref ) = Type ( "DocumentRef.AssetsWriteOff" ) ) then
		name = "Document.AssetsInventory";
	else
		name = "Document.IntangibleAssetsInventory";
	endif; 
	s = "
	|// @Fields
	|select Document.Company as Company
	|from " + name + " as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item 
	|from " + name + ".Items as Items
	|where Items.Ref = &Base
	|and Items.Difference < 0
	|";
	Form.Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByInventory ( Form )
	
	object = Form.Object;
	FillPropertyValues ( object, Form.Env.Fields );
	object.Inventory = Form.Base;
	
EndProcedure 

&AtServer
Procedure itemsByInventory ( Form )
	
	table = Form.Env.Items;
	if ( table.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	Form.Object.Items.Load ( table );
	
EndProcedure

&AtServer
Procedure setLinks ( Form )
	
	object = Form.Object;
	SQL.Init ( Form.Env );
	env = Form.Env;
	sqlLinks ( Form );
	if ( env.Selection.Count () = 0 ) then
		Form.ShowLinks = false;
	else
		env.Q.SetParameter ( "Inventory", object.Inventory );
		SQL.Perform ( env );
		setURLPanel ( Form );
	endif;

EndProcedure 

&AtServer
Procedure sqlLinks ( Form )
	
	inventory = Form.Object.Inventory;
	exists = not inventory.IsEmpty ();
	if ( exists ) then
		type = TypeOf ( inventory );
		if ( type = Type ( "DocumentRef.AssetsInventory" ) ) then
			name = "Document.AssetsInventory";
		else
			name = "Document.IntangibleAssetsInventory";
		endif; 
		s = "
		|// #Inventory
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from " + name + " as Documents
		|where Documents.Ref = &Inventory
		|";
		Form.Env.Selection.Add ( s );
	endif;
	Form.InventoryExists = exists;
	
EndProcedure 

&AtServer
Procedure setURLPanel ( Form )
	
	parts = new Array ();
	env = Form.Env;
	object = Form.Object;
	if ( Form.InventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( env.Inventory, object.Inventory.Metadata () ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		Form.ShowLinks = false;
	else
		Form.ShowLinks = true;
		Form.Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Form ) export
	
	object = Form.Object;
	Forms.DeleteLastRow ( object.Items, "Item" );
	AssetsWriteOffForm.CalcTotals ( object );
	
EndProcedure

Procedure CalcTotals ( Object ) export
	
	items = Object.Items;
	amount = items.Total ( "Total" );
	vat = items.Total ( "VAT" );
	Object.VAT = vat;
	Object.Amount = amount;
	Object.GrossAmount = amount - ? ( Object.VATUse = 2, vat, 0 );
	
EndProcedure 

&AtServer
Procedure ApplyExpenseAccount ( Form ) export
	
	readAccount ( Form );
	adjustDims ( Form.AccountData, Form.Object );
	labelDims ( Form );
	Appearance.Apply ( Form, "ExpensesLevel" );
	      	
EndProcedure 

Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure 

&AtClient
Procedure ShowDetails ( Form ) export
	
	object = Form.Object;
	if ( object.Detail
		and detailsExist ( object ) ) then
		Output.RemoveDetails ( ThisObject, Form );
	else
		switchDetail ( Form );
	endif; 
	
EndProcedure

&AtClient
Procedure switchDetail ( Form )
	
	object = Form.Object;
	object.Detail = not object.Detail;
	Appearance.Apply ( Form, "Object.Detail" );
	
EndProcedure 

&AtClient
Function detailsExist ( Object )
	
	for each row in Object.Items do
		if ( not row.ExpenseAccount.IsEmpty () ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure RemoveDetails ( Answer, Form ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	clearDetails ( Form );
	switchDetail ( Form );
	
EndProcedure 

&AtClient
Procedure clearDetails ( Form )
	
	for each row in Form.Object.Items do
		row.ExpenseAccount = undefined;
		row.Dim1 = undefined;
		row.Dim2 = undefined;
		row.Dim3 = undefined;
		row.Product = undefined;
		row.ProductFeature = undefined;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ItemsBeforeRowChange ( Form ) export
	
	readTableAccount ( Form );
	enableDims ( Form );
	
EndProcedure

&AtClient
Procedure readTableAccount ( Form )
	
	Form.AccountData = GeneralAccounts.GetData ( Form.ItemsRow.ExpenseAccount );
	
EndProcedure 

&AtClient
Procedure enableDims ( Form )
	
	fields = Form.AccountData.Fields;
	level = fields.Level;
	items = Form.Items;
	for i = 1 to 3 do
		disable = ( level < i );
		items [ "ItemsDim" + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ItemsOnEditEnd ( Form ) export
	
	resetAnalytics ( Form );
	AssetsWriteOffForm.CalcTotals ( Form.Object );
	
EndProcedure

&AtClient
Procedure resetAnalytics ( Form )
	
	items = Form.Items;
	items.ItemsDim1.ReadOnly = false;
	items.ItemsDim2.ReadOnly = false;
	items.ItemsDim3.ReadOnly = false;
	
EndProcedure 

&AtClient
Procedure ItemsItemOnChange ( Form ) export
	
	applyItem ( Form );
	
EndProcedure

&AtClient
Procedure applyItem ( Form )
	
	row = Form.ItemsRow;
	data = DF.Values ( row.Item, "VAT, VAT.Rate as Rate" );
	row.VATCode = data.VAT;
	row.VATRate = data.Rate;
	Computations.Total ( row, Form.Object.VATUse );
	
EndProcedure 

&AtClient
Procedure ItemsExpenseAccountOnChange ( Form ) export
	
	readTableAccount ( Form );
	adjustDims ( Form.AccountData, Form.ItemsRow );
	enableDims ( Form );
	
EndProcedure

&AtClient
Procedure ChooseDim ( Form, Item, Level, StandardProcessing ) export
	
	object = Form.Object;
	row = Form.ItemsRow;
	p = Dimensions.GetParams ();
	p.Company = object.Company;
	p.Level = Level;
	p.Dim1 = row.Dim1;
	p.Dim2 = row.Dim2;
	p.Dim3 = row.Dim3;
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

&AtClient
Function GetFilters ( Object ) export
	
	filters = new Array ();
	filters.Add ( DC.CreateParameter ( "Company", Object.Company ) );
	value = Periods.GetBalanceDate ( Object );
	if ( value <> undefined ) then
		item = DC.CreateParameter ( "Date" );
		item.Value = value;
		item.Use = true;
		filters.Add ( item );
	endif;
	return filters;
	
EndFunction

&AtClient
Procedure ApplyVATUse ( Form ) export
	
	object = Form.Object;
	vatUse = object.VATUse;
	for each row in object.Items do
		Computations.Total ( row, vatUse );
	enddo; 
	AssetsWriteOffForm.CalcTotals ( object );
	Appearance.Apply ( Form, "Object.VATUse" );
	
EndProcedure