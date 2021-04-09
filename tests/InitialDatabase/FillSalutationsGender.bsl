Commando ( "e1cib/list/Catalog.Salutations" );
list = With ();

setGender ( "Г-жа", "Female", list );
setGender ( "Г-н", "Male", list );

//  ************
//	Procedures
//  ************

Procedure setGender ( Description, Gender, List )

	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Description;
	Call ( "Common.Find", p );

	With ( List );
	Click ( "#FormChange" );
	With ();
	Set ( "#Gender", Gender );
	Click ( "#FormWriteAndClose" );
	
	With ( List );

EndProcedure





