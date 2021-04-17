StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description" );
p.Insert ( "Code" );
p.Insert ( "Method", "Hourly Rate" );
if ( Call ( "Common.AppIsCont" ) ) then
	p.Insert ( "Account", "5311" );
else
	p.Insert ( "Account", "21000" );
endif;	
p.Insert ( "Base", new Array () ); // Array of compensaton names
p.Insert ( "Insurance" );
return p;
