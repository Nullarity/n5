
Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.Invoice" );
With ( "Invoice (create)" );
Click ( "#FormWrite" );
Click ( "#FormDocumentInvoiceInvoice" );

With ( "Invoice: Print" );
Click ( "#TabDocSaveToDocuments" );

With ( "Document (create)" );

if ( "TabDoc" <> CurrentSource.GetCurrentItem ().Name ) then
	Stop ( "Page Table should be active now and TabDoc field should be filled by Invoice print form" );
endif;

if ( Right ( Get ( "#PageTable" ).TitleText, 1 ) <> "*" ) then
	Stop ( "Caption of table page should have asterik in the end" );
endif;
