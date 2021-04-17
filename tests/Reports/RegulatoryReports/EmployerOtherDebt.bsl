OpenMenu ( "Settings / Application" );
form = With ( "Application Settings" );
Activate ( "!AccountingPage" );
date = Format ( BegOfYear ( CurrentDate () ), "DLF=D" );
Put ( "!SetupDate", date );
table = Activate ( "!Settings" );
search = new Map ();
search [ "Parameter" ] = "Employer Other Debt";
table.GotoRow ( search, RowGotoDirection.Down );
field = table.GetObject ( , "Parameter", "SettingsDescription" );
field.Activate ();
table.Choose ();
With ( "Employer Other Debt: Setup" );
if ( Call ( "Common.AppIsCont" ) ) then
	if ( _ = undefined ) then
		Put ( "!Value", "5412" );
	else
		Put ( "!Value", _ );
	endif;	
else
	Put ( "!Value", "12800" );
endif;
Put ( "#SetupDate", date );
Click ( "!FormOK" );
With ( form );
Click ( "!FormWriteAndClose" );
