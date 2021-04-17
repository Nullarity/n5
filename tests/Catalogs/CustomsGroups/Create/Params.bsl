StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description", "_Custom group: " + CurrentDate () );
p.Insert ( "Payments", new Array () );
return p;
