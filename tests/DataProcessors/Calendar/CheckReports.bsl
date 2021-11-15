// Open Calendar
// Generate two reports: Worklog, Project Analysis

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/app/DataProcessor.Calendar" );
With();
Click("#OpenWorkLog");
Click("#OpenProjectAnalysis");
