StandardProcessing = false;

date = CurrentDate ();
p = new Structure ();
p.Insert ( "Customer" );
p.Insert ( "Description", "_Project: " + date );
p.Insert ( "ProjectType" );
p.Insert ( "DateStart", Format ( date, "DLF=D" ) );
p.Insert ( "DateStart", Format ( date, "DLF=D" ) );
return p;
