
&AtServer
Procedure OnCreate ( Form ) export
	
	loadParams ( Form );
	Options.Company ( Form, Form.Object.Company );
	readAppearance ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	rules.Add ( "
	|GroupFields unlock TableRow.Edit
	|" );
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure loadParams ( Form )
	
	p = Form.Parameters;
	Form.Object.Company = p.Company;
	Form.row = p.row;
	Form.ReadOnly = p.ReadOnly;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Form ) export
	
	loadData ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtClient
Procedure loadData ( Form )
	
	object = Form.Object;
	formOwner = Form.FormOwner;
	owner = formOwner.Object;
	object.Date = owner.Date;
	tableRow = object.Taxes.Add ();
	FillPropertyValues ( tableRow, formOwner.Items.Taxes.CurrentData );
	if ( Form.row ) then
		tableRow.Edit = true;
	endif; 
	Form.TableRow = tableRow;
	
EndProcedure 

&AtClient
Procedure EditOnChange ( Form ) export
	
	Appearance.Apply ( Form, "TableRow.Edit" );
	
EndProcedure

&AtClient
Procedure TaxOnChange ( Form ) export
	
	setMethod ( Form );
	
EndProcedure

&AtClient
Procedure setMethod ( Form )
	
	tableRow = Form.TableRow;
	tableRow.Method = DF.Pick ( tableRow.Tax, "Method" );
	
EndProcedure
