
Procedure Read ( Form ) export
	
	SetPrivilegedMode ( true );
	FillPropertyValues ( Form, Form.Parameters.Key );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure 

Procedure readAppearance ( Form )
	
	rules = new Array ();
	rules.Add ( "
	|DisconnectedWarning show Disconnected;
	|" );
	Appearance.Read ( Form, rules );
	
EndProcedure

Procedure Save ( Form ) export
	
	SetPrivilegedMode ( true );
	obj = Form.Parameters.Key.GetObject ();
	FillPropertyValues ( obj, Form );
	obj.Write ();
	Form.Modified = false;
	
EndProcedure 
