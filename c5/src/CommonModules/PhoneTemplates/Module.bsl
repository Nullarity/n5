
&AtServer
Procedure Set ( Form, Controls ) export
	
	templates = PhoneTemplatesSrv.GetList ();
	if ( templates.Count () = 0 ) then
		return;
	endif; 
	default = DF.Pick ( Constants.Phone.Get (), "Mask" );
	isNew = Form.Object.Ref.IsEmpty ();
	items = Form.Items;
	for each control in Conversion.StringToArray ( Controls ) do
		item = items [ control ];
		phone = Forms.ItemValue ( Form, item );
		if ( isNew
			or phone = "" ) then
			mask = default;
		else
			mask = PhoneTemplatesSrv.PickMask ( phone, templates );
		endif; 
		if ( mask <> undefined ) then
			item.Mask = mask;
		endif; 
	enddo; 

EndProcedure 

&AtClient
Procedure Choice ( Form, Item ) export
	
	list = PhoneTemplatesSrv.GetMenu ();
	params = new Structure ( "Form, Item", Form, Item );
	Form.ShowChooseFromMenu ( new NotifyDescription ( "MaskSelected", ThisObject, params ), list, Item );
	
EndProcedure 

&AtClient
Procedure MaskSelected ( Mask, Params ) export
	
	if ( Mask = undefined ) then
		return;
	endif; 
	value = Mask.Value;
	if ( TypeOf ( value ) = Type ( "String" ) ) then
		setMask ( Params, value );
	else
		if ( value = Enum.PhonesActionsNew () ) then
			p = new Structure ( "ChoiceMode", true );
			callback = new NotifyDescription ( "MaskCreated", ThisObject, Params );
			OpenForm ( "Catalog.Phones.ObjectForm", p, , , , , callback );
		elsif ( value = Enum.PhonesActionsList () ) then
			OpenForm ( "Catalog.Phones.ListForm" );
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure setMask ( Params, Mask )
	
	item = Params.Item;
	item.Mask = Mask;
	Params.Form.CurrentItem = item;
	
EndProcedure 

&AtClient
Procedure MaskCreated ( Mask, Params ) export
	
	if ( Mask = undefined ) then
		return;
	endif; 
	setMask ( Params, Mask );
	
EndProcedure 

&AtServer
Function Check ( Object, Fields ) export
	
	ok = true;
	ref = Object.Ref;
	templates = PhoneTemplatesSrv.GetList ();
	if ( templates.Count () = 0 ) then
		return ok;
	endif; 
	for each field in Conversion.StringToArray ( Fields ) do
		phone = Object [ field ];
		if ( phone = "" ) then
			continue;
		endif; 
		mask = PhoneTemplatesSrv.PickMask ( phone, templates );
		if ( mask = undefined ) then
			Output.WrongPhone ( , field, ref );
			ok = false;
		endif; 
	enddo; 
	return ok;

EndFunction 
