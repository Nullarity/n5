﻿// Opens list and set filter by memo
Commando("e1cib/list/Document.Assembling");
p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = _;
Call("Common.Find", p);
