Call ( "Common.Init" );

date = CurrentDate ();
file = "5 files";
list = Run ( "Filter", new Structure ( "Subject", file ) );

Click ( "#Copy1" );

With ( "Document (create)" );

Set ( "#Subject", date );
Click ( "#FormWrite" );
