
Procedure Proceed () export

	list = fetch ();
	if ( list.Count () = 0 ) then
		return;
	endif;
	createTables ();
	for each entry in list do
		embeddings = AIServer.GetVectors ( entry.Text, entry.TextRu, entry.Table );
		AIServer.AddToSearch ( entry.Table, String ( entry.ID ), embeddings );
		withdraw ( entry );
	enddo;
	
EndProcedure

Function fetch ()

	s = "
	|select Pool.Object as Object, uuid ( Pool.Object ) as ID,
	|	Pool.Object.Description as Text, isnull ( Pool.Object.DescriptionRu, """" ) as TextRu,
	|	case when Pool.Object refs Catalog.Organizations then ""organizations""
	|		when Pool.Object refs Catalog.Countries then ""countries""
	|		when Pool.Object refs Catalog.States then ""states""
	|		when Pool.Object refs Catalog.Cities then ""cities""
	|	end as Table
	|from InformationRegister.EmbeddingPool as Pool
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();

EndFunction

Procedure createTables ()
	
	list = new Array ();
	list.Add ( new Structure ( "Name, Tenant", "organizations", true ) );
	list.Add ( new Structure ( "Name, Tenant", "countries", true ) );
	list.Add ( new Structure ( "Name, Tenant", "states", true ) );
	list.Add ( new Structure ( "Name, Tenant", "cities", true ) );
	for each table in list do
		AIServer.CreateTable ( table.Name, table.Tenant );
	enddo;
	
EndProcedure

Procedure withdraw ( Entry )
	
	record = InformationRegisters.EmbeddingPool.CreateRecordManager ();
	record.Object = Entry.Object;
	record.Delete ();
	
EndProcedure

Procedure Enroll ( Object ) export

	r = InformationRegisters.EmbeddingPool.CreateRecordManager ();
	r.Object = Object;
	r.Write ();

EndProcedure