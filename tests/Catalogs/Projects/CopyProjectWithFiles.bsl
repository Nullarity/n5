// Conditions:
// Project with description "5 files" should exist
// Files should be inside

Call ( "Common.Init" );

CloseAll ();

date = CurrentDate ();
file = "5 files";
list = Run ( "Filter", new Structure ( "Description", file ) );

Click ( "#FormCopy" );

With ( "Projects (create)" );

Set ( "#Description", date );
Click ( "#FormWrite" );
