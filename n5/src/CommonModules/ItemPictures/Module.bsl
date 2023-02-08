
&AtClient
Procedure ClickProcessing ( Operation, FormID ) export
	
	if ( Operation = "" ) then
		return;
	endif; 
	command = Left ( Operation, 3 );
	code = Mid ( Operation, 5 );
	if ( command = Enum.PictureCommandsAdd () ) then
		callback = new NotifyDescription ( "NewPicture", ThisObject, code );
		Images.Load ( callback, FormID );
	elsif ( command = Enum.PictureCommandsDelete () ) then
		Output.DeletePictureConfirmation ( ThisObject, code );
	elsif ( command = Enum.PictureCommandsOpenGallery () ) then
		openPictures ( code );
	endif; 
	
EndProcedure 

&AtClient
Procedure NewPicture ( Data, Code ) export
	
	p = new Structure ( "Code, Picture", Code, Data.Picture );
	bridge = new NotifyDescription ( "PictureDescription", ThisObject, p );
	description = FileSystem.GetFileName ( Data.File );
	ShowInputString ( bridge, description, Output.PictureDescription () );

EndProcedure 

&AtClient
Procedure PictureDescription ( Description, Params ) export
	
	ImagesSrv.Add ( Params.Code, Params.Picture, description );
	Notify ( Enum.RefreshItemPictures () );
	
EndProcedure 

&AtClient
Procedure DeletePictureConfirmation ( Answer, Code ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	ImagesSrv.Delete ( Code );
	Notify ( Enum.RefreshItemPictures () );
	
EndProcedure 

&AtClient
Procedure openPictures ( Code )
	
	OpenForm ( "CommonForm.Pictures", new Structure ( "ID", Code ) );
	
EndProcedure 

&AtServer
Procedure RestoreGallery ( Form ) export
	
	value = CommonSettingsStorage.Load ( getSettings ( Form ) );
	Form.PicturesEnabled = ? ( value = undefined, false, value );
	ItemPictures.Refresh ( Form );
	
EndProcedure 

&AtServer
Function getSettings ( Form )
	
	type = TypeOf ( Form.Object.Ref );
	if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
		return Enum.SettingsSalesOrderPicturesEnabled ();
	elsif ( type = Type ( "DocumentRef.InternalOrder" ) ) then
		return Enum.SettingsInternalOrderPicturesEnabled ();
	elsif ( type = Type ( "DocumentRef.PurchaseOrder" ) ) then
		return Enum.SettingsPurchaseOrderPicturesEnabled ();
	endif; 
	
EndFunction 

Procedure Refresh ( Form ) export
	
	product = Form.ShownProduct;
	if ( Form.PicturesEnabled
		and product <> undefined ) then
		Form.Picture = ImagesSrv.Build ( product, Form.Resize );
	else
		Form.Picture = "";
	endif; 
	
EndProcedure 

&AtServer
Procedure Toggle ( Form ) export
	
	flag = not Form.PicturesEnabled;
	Form.PicturesEnabled = flag;
	ItemPictures.Refresh ( Form );
	LoginsSrv.SaveSettings ( getSettings ( Form ), , flag );
	Appearance.Apply ( Form, "PicturesEnabled" );
	
EndProcedure 
