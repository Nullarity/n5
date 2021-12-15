// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readAccount ( ThisObject, "Dr" );
	readAccount ( ThisObject, "Cr" );
	enableSide ( ThisObject, "Dr" );
	enableSide ( ThisObject, "Cr" );

EndProcedure

&AtClientAtServerNoContext
Procedure readAccount ( Form, Side )
	
	object = Form.Object;
	Form [ Side + "Data" ] = new FixedStructure ( GeneralAccounts.GetData ( object [ "Account" + Side ] ) );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure enableSide ( Form, Side )
	
	data = ? ( Side = "Dr", Form.DrData, Form.CrData );
	dims = data.Dims;
	fields = data.Fields;
	items = Form.Items;
	level = fields.Level;
	dim = "Dim" + Side;
	for i = 1 to 3 do
		item = items [ dim + i ];
		if ( i > level ) then
			item.Enabled = false;
			item.Title = "";
		else
			item.Enabled = true;
			item.Title = dims [ i - 1 ].Presentation;
		endif;
	enddo; 

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OperationOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = Object.Operation;
	
EndProcedure 

&AtClient
Procedure AccountDrOnChange ( Item )

	applyAccount ( "Dr" );

EndProcedure

&AtClient
Procedure applyAccount ( Side )
	
	readAccount ( ThisObject, Side );
	adjustAnalytics ( Side );
	enableSide ( ThisObject, Side );
	      	
EndProcedure 

&AtClient
Procedure adjustAnalytics ( Side )
	
	data = ThisObject [ Side + "Data" ];
	fields = data.Fields;
	dims = data.Dims;
	dim = "Dim" + Side;
	dim1 = dim + "1";
	dim2 = dim + "2";
	dim3 = dim + "3";
	level = fields.Level;
	if ( level > 0 ) then
		Object [ dim1 ] = dims [ 0 ].ValueType.AdjustValue ( Object [ dim1 ] );
	else
		Object [ dim1 ] = null;
	endif; 
	if ( level > 1 ) then
		Object [ dim2 ] = dims [ 1 ].ValueType.AdjustValue ( Object [ dim2 ] );
	else
		Object [ dim2 ] = null;
	endif; 
	if ( level > 2 ) then
		Object [ dim3 ] = dims [ 2 ].ValueType.AdjustValue ( Object [ dim3 ] );
	else
		Object [ dim3 ] = null;
	endif; 

EndProcedure

&AtClient
Procedure AccountCrOnChange ( Item )
	
	applyAccount ( "Cr" );

EndProcedure
