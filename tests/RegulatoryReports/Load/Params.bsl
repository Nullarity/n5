StandardProcessing = false;

p = new Structure ();

// Path to the service scenario where report template and program code are stored
p.Insert ( "Path" );

// Can be empty.
// Path to scenario which can modify source script before writing to file system
p.Insert ( "BeforeSavingScript" );
return p;
