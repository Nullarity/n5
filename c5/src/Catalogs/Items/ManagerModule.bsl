#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	put ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	s = "
	|// #Barcodes
	|select Barcodes.Barcode as Barcode, Barcodes.Feature.Description as Feature,
	|	Barcodes.Item.Description as Item, Package.Description as Package,
	|	Barcodes.Series.Description as Series
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Item = &Item
	|";
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Item", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure put ( Params, Env )
	
	area = Env.T.GetArea ( "Row|Column" );
	space = Env.T.GetArea ( "Row|Space" );
	picture = area.Drawings.Barcode;
	p = PrintBarcodes.GetParams ();
	p.Width = picture.Width;
	p.Height = picture.Height;
	tabDoc = Params.TabDoc;
	for each row in Env.Barcodes do
		p.Barcode = row.Barcode;
		area.Drawings.Barcode.Picture = PrintBarcodes.GetPicture ( p );
		area.Parameters.Description = Print.FormatItem ( row.Item, row.Package, row.Feature, row.Series ); 
		for i = 1 to 7 do
			for j = 1 to 3 do
				if ( j = 1 ) then
					tabDoc.Put ( area );
				else
					tabDoc.Join ( area );
				endif; 
				if ( j < 3 ) then
					tabDoc.Join ( space );
				endif; 
			enddo; 
		enddo; 
	enddo; 

EndProcedure

#endregion

#endif