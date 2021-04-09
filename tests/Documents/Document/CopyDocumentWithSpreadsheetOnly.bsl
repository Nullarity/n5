
Call ( "Common.Init" );
CloseAll ();

testValue = "test";

MainWindow.ExecuteCommand ( "e1cib/data/Document.Document" );
With ( "Document (create)" );
Set ( "#Subject", "Test table copy:" + CurrentDate () );
Set ( "#PageTable / #TabDoc [R1C1]", testValue );
Click ( "#FormWrite" );
Click ( "#FormCopy" );

With ( "Document (create)" );

if ( "TabDoc" <> CurrentSource.GetCurrentItem ().Name ) then
	Stop ( "Page Table should be active now" );
endif;

if ( Fetch ( "#TabDoc [R1C1]" ) <> testValue ) then
	Stop ( "#TabDoc [R1C1] should have <" + testValue + ">" );
endif;

if ( Right ( Get ( "#PageTable" ).TitleText, 1 ) <> "*" ) then
	Stop ( "Caption of table page should have asterik in the end" );
endif;
