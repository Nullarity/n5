formDoc = With ( "Entry*" );
Click ( "#FormReportRecordsShow" );
form = With ( "Records: Entry*" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );
Close ( formDoc );
