
Function DeepFunction ( val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	_script = _Procedures [ _Name ];
	#region ExecutionContext
	result = undefined;
	Execute ( _script );
	#endregion
	return result;
	
EndFunction 

Procedure DeepProcedure ( val _Procedures, _Name, _P1 = undefined, _P2 = undefined, _P3 = undefined, _P4 = undefined, _P5 = undefined, _P6 = undefined, _P7 = undefined, _P8 = undefined, _P9 = undefined, _P10 = undefined, _P11 = undefined, _P12 = undefined, _P13 = undefined, _P14 = undefined, _P15 = undefined, _P16 = undefined, _P17 = undefined, _P18 = undefined, _P19 = undefined, _P20 = undefined ) export
	
	_script = _Procedures [ _Name ];
	#region ExecutionContext
	Execute ( _script );
	#endregion

EndProcedure
