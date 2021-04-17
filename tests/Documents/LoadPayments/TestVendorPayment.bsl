formDoc = With ( "Vendor Payment #*" );
Click ( "#FormReportRecordsShow" );
form = With ( "Records: Vendor Payment #*" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );
Close ( formDoc );