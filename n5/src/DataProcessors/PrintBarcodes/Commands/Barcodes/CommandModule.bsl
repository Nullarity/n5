
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )
	
	type = TypeOf ( Source );
	if ( type = Type ( "CatalogRef.Items" )
		or type = Type ( "CatalogRef.Series" ) ) then
		p = Print.GetParams ();
		p.Manager = "DataProcessors.PrintBarcodes";
		p.Objects = Source;
		p.Key = "Barcodes";
		p.Template = "Template";
		Print.Print ( p );
	else
		OpenForm ( "DataProcessor.PrintBarcodes.Form", new Structure ( "Document", Source ),
			ExecuteParameters.Source );
	endif;

EndProcedure
