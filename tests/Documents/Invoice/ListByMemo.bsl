﻿// Opens list of sales orders and set filter by memo
Commando("e1cib/list/Document.Invoice");
p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = _;
Call("Common.Find", p);
