// Opens list of documents and set filter by memo
Commando("e1cib/list/Document.AdjustDebts");
p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = _;
Call("Common.Find", p);
