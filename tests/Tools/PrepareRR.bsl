//p = Call ( "Tools.BuildRRPackage.Params" );
//p.Release = "5_0_4_1";
//p.Path = "D:\Cont 5\!Release\Update";
//list = p.Remove;
//list.Add ( "1_M" );
//list = p.Update;
//list.Add ( "InitialDatabase.RegulatoryReports.Month.Munca1" );
//list.Add ( "InitialDatabase.RegulatoryReports.Month.Munca2" );
//
//Call ( "Tools.BuildRRPackage", p );

// Creates ZIP-file for regulatory reports
p = Call ( "Tools.BuildRRPackage.Params" );
p.Release = "5_0_19_1";
p.Path = "/home/dmitry/Desktop";
list = p.Update;
list.Add ( "InitialDatabase.RegulatoryReports.Month.IPC21" );
Call ( "Tools.BuildRRPackage", p );