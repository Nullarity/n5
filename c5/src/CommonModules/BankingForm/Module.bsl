
Procedure ChooseLoading ( App, Item ) export
	
	params = new Structure ( "App, Item", App, Item );
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChooseLoading", ThisObject, params ) );
	
EndProcedure

Procedure ContinueChooseLoading ( Result, Params ) export

	dialog = new FileDialog ( FileDialogMode.Open );
	dialog.Multiselect = false;
	fileSetup ( Params.App, dialog );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject, Params.Item ) );

EndProcedure

Procedure fileSetup ( App, Dialog ) 

	if ( App = PredefinedValue ( "Enum.Banks.VictoriaBank" )
		or App = PredefinedValue ( "Enum.Banks.Energbank" )
		or App = PredefinedValue ( "Enum.Banks.ProCreditBank" ) ) then
		filter = "Text (*.txt)|*.txt";
		Dialog.FullFileName = "kl_to_1c.txt";
	elsif ( App = PredefinedValue ( "Enum.Banks.Mobias" )
		or App = PredefinedValue ( "Enum.Banks.MAIB" )
		or App = PredefinedValue ( "Enum.Banks.Eximbank" ) ) then
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( App = PredefinedValue ( "Enum.Banks.FinComPay" )
		or App = PredefinedValue ( "Enum.Banks.Comert" ) ) then
		filter = "XML (*.xml)|*.xml";
	elsif ( App = PredefinedValue ( "Enum.Banks.EuroCreditBank" ) ) then
		filter = "(*.*)|*.*";
	endif;
	Dialog.Filter = filter;

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

Procedure ChooseUnloading ( App, Item ) export
	
	params = new Structure ( "App, Item", App, Item );
	LocalFiles.Prepare ( new NotifyDescription ( "ContinueChooseUnloading", ThisObject, params ) );
	
EndProcedure

Procedure ContinueChooseUnloading ( Result, Params ) export

	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Multiselect = false;
	fileSetupUnloading ( Params.App, dialog );
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject, Params.Item ) );

EndProcedure

Procedure fileSetupUnloading ( App, Dialog ) 

	file = "ExportPayments";
	ext = ".txt";
	filter = "Text (*.txt)|*.txt";
	if ( app.IsEmpty() ) then
		filter = "(*.*)|*.*";
	elsif ( app = PredefinedValue ( "Enum.Banks.Mobias" ) ) then
		file = "Plat";
		ext = ".dbf";
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.MAIB" ) ) then
		file = maibFile ();
		ext = ".dbf";
		filter = "DBF (*.dbf)|*.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.FinComPay" )
	 	or app = PredefinedValue ( "Enum.Banks.Comert" ) ) then
		ext = ".xml";
		filter = "XML (*.xml)|*.xml";
	elsif ( app = PredefinedValue ( "Enum.Banks.EuroCreditBank" ) ) then
		ext = "";
		filter = "(*.*)|*.*";
	endif;
	Dialog.Filter = filter;
	Dialog.FullFileName	= file + ext;

EndProcedure

Function maibFile () 

	date = CurrentDate ();
	month = Month ( date );
	if ( month = 10 ) then
		month = "A";	
	elsif ( month = 11 ) then
		month = "B";	
	elsif ( month = 12 ) then
		month = "C";	
	endif;
	return "IDOC" + Format ( date, "DF='dd'" ) + month;

EndFunction
