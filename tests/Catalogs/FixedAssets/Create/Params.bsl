﻿p = new Structure ();
p.Insert ( "Description", "_Fixed Asset: " + CurrentDate () );
if ( AppName = "Cont5" ) then
	p.Insert ( "VAT", "20%" );
endif;
return p;