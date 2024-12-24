Procedure AdjustTemperature ( Form, Reset ) export
	
	object = Form.Object;
	if ( object.Provider = PredefinedValue ( "Enum.AIProviders.Anthropic" ) ) then
		max = 1;
		default = 0.5;
	else
		max = 2;
		default = 1;
	endif;
	Form.Items.Temperature.MaxValue = max;
	if ( Reset
		or object.Temperature > max ) then
		object.Temperature = default;
	endif;
	
EndProcedure
