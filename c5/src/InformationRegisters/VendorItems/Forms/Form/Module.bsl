// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	IsNew = Record.SourceRecordKey.IsEmpty ();
	if ( IsNew ) then
		setPackage ( ThisObject );
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Vendor lock filled ( Record.Vendor ) and IsNew;
	|Item lock filled ( Record.Item ) and IsNew;
	|Package enable not Service
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClientAtServerNoContext
Procedure setPackage ( Form )
	
	record = Form.Record;
	fields = DF.Values ( record.Item, "Service, Package" );
	if ( fields.Service ) then
		Form.Service = true;
		record.Package = undefined;
	else
		Form.Service = false;
		record.Package = fields.Package;
	endif; 
	Appearance.Apply ( Form, "Service" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ItemOnChange ( Item )
	
	setPackage ( ThisObject );
	
EndProcedure
