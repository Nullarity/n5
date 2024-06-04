
Procedure ChooseLoadingFile ( App, Item ) export
	
	params = new Structure ( "App, Item", App, Item );
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChoosingLoadingFile", ThisObject, params ) );
	
EndProcedure

Procedure ContinueChoosingLoadingFile ( Result, Params ) export

	dialog = new FileDialog ( FileDialogMode.Open );
	dialog.Multiselect = false;
	app = DF.Pick ( Params.App, "Application" );
	if ( app = PredefinedValue ( "Enum.Banks.VictoriaBank" )
		or app = PredefinedValue ( "Enum.Banks.Energbank" )
		or app = PredefinedValue ( "Enum.Banks.ProCreditBank" ) ) then
		filter = "Text (*.txt)|*.txt";
		dialog.FullFileName = "kl_to_1c.txt";
	elsif ( app = PredefinedValue ( "Enum.Banks.Mobias" )
		or app = PredefinedValue ( "Enum.Banks.MAIB" )
		or app = PredefinedValue ( "Enum.Banks.Eximbank" ) ) then
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.FinComPay" )
		or app = PredefinedValue ( "Enum.Banks.Comert" ) ) then
		filter = "XML (*.xml)|*.xml";
	elsif ( app = PredefinedValue ( "Enum.Banks.EuroCreditBank" ) ) then
		filter = "(*.*)|*.*";
	endif;
	dialog.Filter = filter;
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject, Params.Item ) );

EndProcedure

Procedure SelectFile ( Files, Item ) export
		
	if ( Files = undefined ) then
		return;
	endif;
	size = StrLen ( Item.EditText );
	if ( size > 0 ) then
		Item.SetTextSelectionBounds ( 1, size + 1 );
	endif;
	Item.SelectedText = Files [ 0 ];
	
EndProcedure

Procedure ChooseFolder ( Item ) export
	
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChoosingFolder", ThisObject, Item ) );
	
EndProcedure

Procedure ContinueChoosingFolder ( Result, Item ) export

	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject, Item ) );

EndProcedure

Procedure SelectFolder ( Folder, Item ) export
		
	if ( Folder = undefined ) then
		return;
	endif;
	size = StrLen ( Item.EditText );
	if ( size > 0 ) then
		Item.SetTextSelectionBounds ( 1, size + 1 );
	endif;
	Item.SelectedText = Folder [ 0 ];
	
EndProcedure

Procedure ChooseFile ( App, Item ) export
	
	params = new Structure ( "App, Item", App, Item );
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChoosingFile", ThisObject, params ) );
	
EndProcedure

Procedure ContinueChoosingFile ( Result, Params ) export

	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Multiselect = false;
	app = DF.Pick ( Params.App, "Application" );
	if ( app.IsEmpty() ) then
		filter = "(*.*)|*.*";
	elsif ( app = PredefinedValue ( "Enum.Banks.Mobias" ) ) then
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.MAIB" ) ) then
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.FinComPay" )
	 	or app = PredefinedValue ( "Enum.Banks.Comert" ) ) then
		filter = "XML (*.xml)|*.xml";
	elsif ( app = PredefinedValue ( "Enum.Banks.EuroCreditBank" ) ) then
		filter = "(*.*)|*.*";
	else
		filter = "Text (*.txt)|*.txt";
	endif;
	dialog.Filter = filter;
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject, Params.Item ) );

EndProcedure

Procedure ChooseSalaryFile ( App, Item ) export
	
	params = new Structure ( "App, Item", App, Item );
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChoosingSalaryFile", ThisObject, params ) );
	
EndProcedure

Procedure ContinueChoosingSalaryFile ( Result, Params ) export

	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Multiselect = false;
	app = DF.Pick ( Params.App, "Application" );
	if ( app = PredefinedValue ( "Enum.Banks.Eximbank" ) ) then
		filter = "CSV (*.csv)|*.csv";
	elsif ( app = PredefinedValue ( "Enum.Banks.MAIB" ) ) then
		filter = "(*.*)|*.*";
	else
		raise Output.SalaryExportNotSupported ();
	endif;
	Dialog.Filter = filter;
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject, Params.Item ) );

EndProcedure
