formDoc = With ( "Customer Payment #*" );
Click ( "#FormReportRecordsShow" );
form = With ( "Records: Customer Payment #*" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );
Close ( formDoc );