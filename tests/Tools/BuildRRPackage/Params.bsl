StandardProcessing = false;

p = new Structure ();
p.Insert ( "Release" ); // For example: 5_0_8_7
p.Insert ( "Path" ); // Path to the new ZIP-file
p.Insert ( "Remove", new Array () ); // Array of reports ID, for example: "IPC18"
p.Insert ( "Update", new Array () ); // Full path to the test with RR: "InitialDatabase.RegulatoryReports.Month.IPC18_042019"
return p;
