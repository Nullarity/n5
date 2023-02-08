
Procedure Read ( Form ) export
	
	SetPrivilegedMode ( true );
	FillPropertyValues ( Form, Form.Parameters.Key );
	
EndProcedure 

Procedure Save ( Form ) export
	
	SetPrivilegedMode ( true );
	obj = Form.Parameters.Key.GetObject ();
	FillPropertyValues ( obj, Form );
	obj.Write ();
	Form.Modified = false;
	
EndProcedure 
