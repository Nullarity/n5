Function GetPosition ( val Employee, val Date ) export
	
	SetPrivilegedMode ( true );
	return InformationRegisters.Personnel.GetLast ( Date, new Structure ( "Employee", Employee ) ).Position;

EndFunction 
