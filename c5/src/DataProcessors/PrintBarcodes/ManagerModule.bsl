#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	put ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlPrintData ( Env, Params );
	q = Env.Q;
	q.SetParameter ( "Ref", Params.Reference );
	q.SetParameter ( "User", SessionParameters.User );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintData ( Env, Params )
	
	type = TypeOf ( Params.Reference );
	s = "
	|// @Profile
	|select Users.BarcodeProfile.Template as Template, Users.BarcodeProfile.Angle as Angle,
	|	Users.BarcodeProfile.FontSize as FontSize
	|from Catalog.UserSettings as Users
	|where Users.Owner = &User
	|;";
	if ( type = Type ( "CatalogRef.Items" )
		or type = Type ( "CatalogRef.Series" )
		or type = Type ( "Number" ) ) then
		if ( type = Type ( "CatalogRef.Items" ) ) then
			name = "Item";
		elsif ( type = Type ( "CatalogRef.Series" ) ) then
			name = "Series";
		else
			name = "Barcode";
		endif;
		s = s + "
		|// #Barcodes
		|select Items.Item.FullDescription as Item, Items.Series.Description as Series,
		|	Items.Feature.Description as Feature, 1 as Quantity, Items.Barcode as Barcode,
		|	isnull ( Items.Package.Description, Items.Item.Unit.Code ) as Package
		|from InformationRegister.Barcodes as Items
		|where Items." + name + " = &Ref
		|order by Items.Item.Description
		|";
	else
		name = Metadata.FindByType ( TypeOf ( Params.Reference ) ).Name;
		s = s + "
		|// #Barcodes
		|select Items.Item.FullDescription as Item, Items.Series.Description as Series, Items.Print as Quantity,
		|	Barcodes.Barcode as Barcode, Barcodes.Feature.Description as Feature,
		|	isnull ( Barcodes.Package.Description, Barcodes.Item.Unit.Code ) as Package
		|from Document." + name + ".Items as Items
		|	//
		|	// Barcodes
		|	//
		|	join InformationRegister.Barcodes as Barcodes
		|	on Barcodes.Item = Items.Item
		|	and Barcodes.Series = Items.Series
		|	and Barcodes.Package = Items.Package
		|	and Barcodes.Feature = Items.Feature
		|where Items.Ref = &Ref
		|and Items.Print > 0
		|order by Items.LineNumber
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure

Procedure put ( Params, Env )
	
	profile = Env.Profile;
	storage = profile.Template;
	if ( not ValueIsFilled ( storage ) ) then
		raise Output.UndefinedBarcodeProfile ();
	endif;
	table = Env.Barcodes;
	if ( table.Count () = 0 ) then
		return;
	endif;
	t = storage.Get ();
	area = t.GetArea ();
	picture = area.Drawings.Barcode;
	p = PrintBarcodes.GetParams ();
	p.Width = picture.Width;
	p.Height = picture.Height;
	p.FontSize = profile.FontSize;
	p.Angle = profile.Angle;
	tabDoc = Params.TabDoc;
	page = 1;
	for each row in table do
		for i = 1 to row.Quantity do
			if ( page > 1 ) then
				tabDoc.PutHorizontalPageBreak ();
			endif;
			p.Barcode = row.Barcode;
			area.Drawings.Barcode.Picture = PrintBarcodes.GetPicture ( p );
			area.Parameters.Description = Print.FormatItem ( row.Item, row.Package, row.Feature, row.Series ); 
			tabDoc.Put ( area );
			page = page + 1;
		enddo;
	enddo; 
	
EndProcedure

#endif