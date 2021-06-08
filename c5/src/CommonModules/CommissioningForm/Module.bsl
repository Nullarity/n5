&AtServer
Procedure OnCreateAtServer ( Form ) export

	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		DocumentForm.Init ( object );
		if ( Form.Parameters.Basis = undefined ) then
			fillNew ( Form );
		else
			fillAssets ( Form );
		endif;
	endif;
	setLinksCommissioning ( Form );
	Options.Company ( Form, object.Company );
	StandardButtons.Arrange ( Form );
	
EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	parameters = Form.Parameters;
	if ( not parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	if ( object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		object.Company = settings.Company;
		object.Warehouse = settings.Warehouse;
	else
		object.Company = DF.Pick ( object.Warehouse, "Owner" );
	endif;
	department = object.Department;
	if ( not department.IsEmpty () ) then
		if ( DF.Pick ( department, "Owner" ) <> object.Company ) then
			object.Department = undefined;
		endif; 
	endif;
	fillStakeholders ( Form )
	
EndProcedure

&AtServer
Procedure fillStakeholders ( Form )
	
	SQL.Init ( Form.Env );
	getStakeholders ( Form );
	env = Form.Env;
	header = env.Header;
	object = Form.Object;
	if ( header <> undefined ) then
		FillPropertyValues ( object, header );
	endif; 
	object.Members.Load ( env.Members );
	
EndProcedure

&AtServer
Procedure getStakeholders ( Form )
	
	object = Form.Object;
	ref = object.Ref;
	if ( TypeOf ( ref ) = Type ( "DocumentRef.Commissioning" ) ) then
		table = "Commissioning";
	else
		table = "IntangibleAssetsCommissioning";
	endif;
	s = "
	|select allowed top 1 Documents.Ref as Ref
	|into References
	|from Document." + table + " as Documents
	|where not Documents.DeletionMark
	|and Documents.Date <= &Date
	|and Documents.Ref <> &Ref
	|and Documents.Company = &Company";
	warehouse = object.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		s = s + "
		|and Documents.Warehouse = &Warehouse";
	endif; 
	s = s + "
	|order by Documents.Date desc
	|;
	|// @Header
	|select Documents.Head as Head, Documents.HeadPosition as HeadPosition,
	|	Documents.Approved as Approved, Documents.ApprovedPosition as ApprovedPosition
	|from Document." + table + " as Documents
	|where Documents.Ref in ( select Ref from References )
	|;
	|// #Members
	|select Members.Member as Member, Members.Position as Position
	|from Document." + table + ".Members as Members
	|where Members.Ref in ( select Ref from References )
	|order by Members.LineNumber
	|";
	env = Form.Env;
	env.Selection.Add ( s );
	q = env.Q;
	q.SetParameter ( "Date", Periods.GetDocumentDate ( object ) );
	q.SetParameter ( "Ref", ref );
	q.SetParameter ( "Company", object.Company );
	q.SetParameter ( "Warehouse", warehouse );
	SQL.Perform ( env );

EndProcedure

&AtServer
Procedure fillAssets ( Form )

	SQL.Init ( Form.Env );
	setContext ( Form );
	getAssetsData ( Form );
	fillHeader ( Form );
	fillTables ( Form );

EndProcedure

&AtServer
Procedure setContext ( Form ) 

	if ( TypeOf ( Form.Parameters.Basis ) = Type ( "DocumentRef.VendorInvoice" ) ) then
		Form.Env.Insert ( "Base", "VendorInvoice" );
	else
		Form.Env.Insert ( "Base", "ExpenseReport" );
	endif;

EndProcedure

&AtServer
Procedure getAssetsData ( Form ) 

	sqlFields ( Form.Env );
	sqlAssets ( Form );
	getData ( Form );

EndProcedure

&AtServer
Procedure sqlFields ( Env ) 

	s = "
	|// @Fields
	|select Document.Company as Company, Document.Warehouse as Warehouse, &Base as Base
	|from Document." + Env.Base + " as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlAssets ( Form ) 

	env = Form.Env;
	base = env.Base;
	s = "
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Package as Package, Items.QuantityPkg as QuantityPkg, Items.Series as Series, 
	|	Items.Quantity as Capacity, Items.Account as Account
	|from Document." + base + ".Items as Items
	|where Items.Ref = &Base
	|and Items.Account.Class = value ( Enum.Accounts.FixedAssets )
	|;
	|// #Assets
	|select Assets.Acceleration as Acceleration, Assets.Charge as Charge, Assets.Expenses as Expenses, 1 as Quantity, Assets.Method as Method, 
	|	Assets.Starting as Starting, Assets.UsefulLife as UsefulLife, true as Posted, 1 as QuantityPkg, 1 as Capacity 
	|";
	if ( TypeOf ( Form.Object.Ref ) = Type ( "DocumentRef.Commissioning" ) ) then
		s = s + ",
		|	Assets.Item as FixedAsset, Assets.LiquidationValue as LiquidationValue, Assets.Schedule as Schedule
		|";
		table = "FixedAssets";
	else
		s = s + ",
		|	Assets.Item as IntangibleAsset
		|";
		table = "IntangibleAssets";
	endif; 
	s = s + "
	|from Document." + base + "." + table + " as Assets
	|where Assets.Ref = &Base
	|";
	env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure getData ( Form ) 

	env = Form.Env;
	q = env.Q;
	q.SetParameter ( "Base", Form.Parameters.Basis );
	SQL.Prepare ( env );
	env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( env, env.Data );

EndProcedure

&AtServer
Procedure fillHeader ( Form ) 

	FillPropertyValues ( Form.Object, Form.Env.Fields );

EndProcedure

&AtServer
Procedure fillTables ( Form ) 

	items = Form.Object.Items;
	env = Form.Env;
	for each row in env.Items do
		newRow = items.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	for each row in env.Assets do
		newRow = items.Add ();
		FillPropertyValues ( newRow, row );
	enddo;

EndProcedure

&AtServer
Procedure setLinksCommissioning ( Form )
	
	if ( Form.Object.Base = undefined ) then
		Form.ShowLinks = false;
	else
		getLinksCommissioning ( Form );
		setURLPanelCommissioning ( Form );
	endif;

EndProcedure

&AtServer
Procedure getLinksCommissioning ( Form ) 

	SQL.Init ( Form.Env );
	sqlLinksCommissioning ( Form );
	env = Form.Env;
	env.Q.SetParameter ( "Base", Form.Object.Base );
	SQL.Perform ( env );

EndProcedure

&AtServer
Procedure sqlLinksCommissioning ( Form )
	
	if ( TypeOf ( Form.Object.Base ) = Type ( "DocumentRef.ExpenseReport" ) ) then
		table = "ExpenseReport";
	else
		table = "VendorInvoice";
	endif;
	s = "
	|// #Links
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document." + table + " as Documents
	|where Documents.Ref = &Base
	|";
	Form.Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanelCommissioning ( Form )
	
	parts = new Array ();
	meta = Metadata.FindByType ( TypeOf ( Form.Object.Base ) );
	parts.Add ( URLPanel.DocumentsToURL ( Form.Env.Links, meta ) );
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		Form.ShowLinks = false;
	else
		Form.ShowLinks = true;
		Form.Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure EditRow ( Form, NewRow = false ) export
	
	if ( Form.ReadOnly ) then
		return;
	endif;
	table = Form.Items.Items;
	if ( table.CurrentData = undefined ) then
		return;
	endif; 
	object = Form.Object;
	p = new Structure ();
	p.Insert ( "Company", object.Company );
	p.Insert ( "row", NewRow );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.Commissioning" ) ) then
		name = "Document.Commissioning.Form.Row";
	else
		name = "Document.IntangibleAssetsCommissioning.Form.Row";
	endif; 
	OpenForm ( name, p, Form );
	
EndProcedure 

&AtClient
Procedure SetReadOnly ( Form ) export

	if ( Form.TableRow.Posted ) then
		Form.Enabled = false;
	endif;

EndProcedure

&AtClient
Procedure MethodOnChage ( Form, FixedAsset = true ) export

	resetFields ( Form, FixedAsset );
	Appearance.Apply ( Form, "TableRow.Method" );
	
EndProcedure

&AtClient
Procedure resetFields ( Form, FixedAsset )
	
	tableRow = Form.TableRow;
	method = tableRow.Method;
	if ( method = PredefinedValue ( "Enum.Amortization.Cumulative" ) ) then
		tableRow.Acceleration = 0;
		if ( FixedAsset ) then
			tableRow.Schedule = undefined;
		endif;
	elsif ( method = PredefinedValue ( "Enum.Amortization.Linear" ) ) then
		tableRow.Acceleration = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure LoadRow ( Form, Params ) export
	
	value = Params.Value;
	data = Form.Items.Items.CurrentData;
	if ( value = undefined ) then
		if ( Params.row ) then
			Form.Object.Items.Delete ( data );
		endif;
	else
		FillPropertyValues ( data, value );
	endif;
  	
EndProcedure

&AtClient
Procedure NewRow ( Form, Clone ) export
	
	Forms.NewRow ( Form, Form.Items.Items, Clone );
	CommissioningForm.EditRow ( Form, true );
	
EndProcedure 

&AtServer
Procedure FixedAssetAppearance ( Form ) export
	
	rules = new Array ();
	rules.Add ( "
	|Schedule enable inlist ( TableRow.Method, Enum.Amortization.Linear, Enum.Amortization.Decreasing );
	|Acceleration enable TableRow.Method = Enum.Amortization.Decreasing;
	|Starting enable TableRow.Charge
	|" );
	type = TypeOf ( Form.Object.Ref );
	if ( type = Type ( "DocumentRef.ExpenseReport" ) ) then
		rules.Add ( "
		|VATCode VAT Total show Object.VATUse > 0;
		|VATAccount show Object.VATUse > 0 and TableRow.Type = Enum.DocumentTypes.Invoice;
		|" );
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		rules.Add ( "
		|CustomsGroup enable Object.Import;
		|VATCode VAT Total show Object.VATUse > 0;
		|VATAccount show not HideVATAccount and Object.VATUse > 0;
		|" );
	endif;
	Appearance.Read ( Form, rules );
	
EndProcedure

&AtServer
Procedure IntangibleAssetAppearance ( Form ) export
	
	rules = new Array ();
	rules.Add ( "
	|Acceleration enable TableRow.Method = Enum.Amortization.Decreasing;
	|Starting enable TableRow.Charge
	|" );
	type = TypeOf ( Form.Object.Ref );
	if ( type = Type ( "DocumentRef.ExpenseReport" ) ) then
		rules.Add ( "
		|VATCode VAT Total show Object.VATUse > 0;
		|VATAccount show Object.VATUse > 0 and TableRow.Type = Enum.DocumentTypes.Invoice;
		|" );
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		rules.Add ( "
		|CustomsGroup enable Object.Import;
		|VATCode VAT Total show Object.VATUse > 0;
		|VATAccount show not HideVATAccount and Object.VATUse > 0;
		|" );
	endif;
	Appearance.Read ( Form, rules );
	
EndProcedure
