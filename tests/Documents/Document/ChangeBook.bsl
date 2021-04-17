Call ( "Common.Init" );
CloseAll ();

subject = Call ( "Documents.Document.CreateAndPublish" );

list = Run ( "Filter", new Structure ( "Subject", subject ) );
list.ChangeRow ();

form = With ( subject );

Choose ( "#Book" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Books;
p.Search = "_Book: " + CurrentDate ();
Call ( "Common.Select", p );

With ( form );
Click ( "#FormWrite" );
Close ();