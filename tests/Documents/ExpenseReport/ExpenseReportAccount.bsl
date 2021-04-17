//OpenMenu ( "Settings / Application" );
//form = With ( "Application Settings" );
//Activate ( "!AccountingPage" );
//date = Format ( BegOfYear ( CurrentDate () ), "DLF=D" );
//Put ( "!SetupDate", date );
//table = Activate ( "!Settings" );
//search = new Map ();
//if ( Call ( "Common.AppIsCont" ) ) then
//	param = "Задолженность подотчетных лиц";
//else
//	param = "Expense Report Account";
//endif;
//search [ "Parameter" ] = param;
//table.GotoRow ( search, RowGotoDirection.Down );
//field = table.GetObject ( , "Parameter", "SettingsDescription" );
//field.Activate ();
//table.Choose ();
//With ( param + ": Setup" );
//if ( Call ( "Common.AppIsCont" ) ) then
//	if ( _ = undefined ) then
//		Put ( "!Value", "22612" );
//	else
//		Put ( "!Value", _ );
//	endif;	
//else
//	Put ( "!Value", "12800" );
//endif;
//Put ( "#SetupDate", date );
//Click ( "!FormOK" );
//With ( form );
//Click ( "!FormWriteAndClose" );
