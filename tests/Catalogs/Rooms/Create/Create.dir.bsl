Commando ( "e1cib/command/Catalog.Rooms.Create" );
With();
description = _.Description;
Set("#Description", description);
Set("#Code", Right(description, 9));
Click("#FormWriteAndClose");