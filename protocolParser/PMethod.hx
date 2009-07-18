import haxe.io.BytesInput;
import haxe.io.BytesOutput;

typedef AS = Array<String>;

class PMethod {
    var m_method:String;
    var m_magic:String;
    var m_request:String;
    var m_response:String;

    var m_send:AS;
    var m_instructions:Array<Dynamic>;

    public function new(_method:String, _magic:String, _request:String, _response:String) {
        m_method = _method;
        m_magic = _magic;
        m_request = _request;
        m_response = _response;
        m_instructions = [];
    }

    public function send():String {
        m_send = [];
        m_send.push("public function "+m_method+"(_k:String):Bool {");
        parseMagic();
        parseRequest();
        parseResponse();
        m_send.push("}\n");
        return m_send.join("\n");
    }

    public function parseMagic():Void{
        var parts = m_magic.split(" ");
        var bo = new BytesOutput();
        var byte1 = Std.parseInt(parts[0]);
        var byte2 = Std.parseInt(parts[1]);
        var b16 = byte1<<8 | byte2;

        m_send.push("m_o.writeUInt16("+b16+");");
    }

    public function parseRequest():Void {
        reqStart(m_request.split(""));
    }

    function reqStart(_stream:AS):Void {
        while(_stream.length > 0) {
            reqStartBlock(_stream);
        }
    }

    function reqStartBlock(_stream:AS):Void {
        //trace(_stream);
        var c = _stream.shift();
        switch(c) {
            case "[":
                reqUnitOrIterator(_stream);
            default:
                throw c+" unexpected "+_stream;
        }
    }

    function reqUnitOrIterator(_stream:AS):Void {
        var c = _stream.shift();
        //trace("reqUnitOrIterator "+c);
        switch(c) {
            case "{":
                reqIterator(_stream);
            default:
                _stream.unshift(c);
                //trace("unit "+_stream);
                reqUnit(_stream);
        }
    }

    function reqUnit(_stream):Void {
        var c = _stream.shift();
        //trace(c);
        var id = new StringBuf();
        while(c != ":") {
            id.addChar(c.charCodeAt(0));
            c = _stream.shift();
        }
        c = _stream.shift(); // num or *
        //trace(c+ " size");
        if(id.toString() == "magic") {
        } else {
            m_send.push("m_o.write"+getWrite(c, "_"+id.toString().charAt(0)));
        }
        //trace(id.toString());
        c = _stream.shift(); // ]
        //trace(c+" exitingUnit");
    }

    function reqIterator(_stream:AS):Void {
        var c = _stream.shift();
        m_send.push("for(i in 0...x.length)  {");
        while(c != "}") {
            switch(c) {
                case "[":
                    reqUnitInIterator(_stream);
                default:
                    throw (c+" reqIterator got unexpected character");
            }
            c = _stream.shift();
        }
        m_send.push("}");
        //trace("exitingIterator }"+);
        _stream.splice(0, 3);
    }

    function reqUnitInIterator(_stream:AS):Void {
        var c = _stream.shift();
        //trace(c);
        var id = new StringBuf();
        while(c != ":") {
            id.addChar(c.charCodeAt(0));
            c = _stream.shift();
        }
        c = _stream.shift(); // num or *
        //trace(c+ " size");
        if(id.toString() == "magic") {
        } else {
            m_send.push("m_o.write"+getWrite(c, id.toString()));
        }
        //trace(id.toString());
        c = _stream.shift(); // ]
        //trace(c+" exitingUnit");
    }

    function getWrite(_c:String, _id:String):String {
        var size = Std.parseInt(_c);
        return switch(size) {
            case 1:
                "Byte("+_id+");";
            case 2:
                 "UInt16("+_id+");";
            case 4:
                "Int31("+_id+");";
            case 8:
                "Bytes(BigInteger("+_id+").toBytes(), 0, 8);";
            default:
                if(_id == "_k") {
                    "String("+_id+");";
                } else {
                    "("+_id+");";
                }
        }
    }

    function parseResponse():Void {
        repStart(m_response.split(""));
    }

    function print(_msg:String):Void {
        //trace(m_method+" "+_msg);
    }

    function repStart(_stream:AS):Void {
        var c = _stream.shift();

        print(c+"repStart");

        switch(c) {
            case "[":
                repUnit(_stream);
            case "(":
                repNone(_stream);
        }
    }

    function repUnit(_stream:AS):Void {
        var c = _stream.shift();
        print(c+" repUnit");
        switch(c) {
            case "c":
                _stream.splice(0, "ode:1]".length);
                if(_stream.length == 0) {
                    print("exit repUnit");
                    m_send.push("return (m_i.readByte() == 0);");
                } else {
                    repRetVal(_stream);
                }
            default:
                throw "unexpected "+c+" expecting c from "+_stream;
        }
    }

    function repNone(_stream:AS):Void {
        _stream.splice(0, "none)".length);
        if(_stream.length > 0) {
            throw "repNone expecting empty stream "+_stream;
        }
    }

    function repRetVal(_stream:AS):Void {
        print("repRetVal");
        m_send.push("var success = (m_i.readByte() == 0);");
        m_send.push("var val = null;");
        m_send.push("if(success) {");
        while(_stream.length > 0) {
            var c = _stream.shift();
            switch(c) {
                case "[":
                    var n = _stream[0];
                    if(n == "{") {
                        repRetValIteration(_stream);
                    } else {
                        repRetValUnit(_stream);
                    }
                case "(":
                    repRetValOption(_stream);
                default:
                    throw "unexpected "+c+" "+_stream;
            }
        }
        m_send.push("}");
    }

    function repRetValUnit(_stream:AS):Void {
        var c = _stream.shift();
        print(c+" repRetValUnit "+_stream);
        var id = new StringBuf();
        while (c != ":") {
            id.addChar(c.charCodeAt(0));
            c = _stream.shift();
        }
        print(id.toString());
        c = _stream.shift();
        m_send.push("var "+id.toString()+" = m_i.read"+getRead(c, id.toString()));

        c = _stream.shift(); // ]
        //trace("exiting repRetValUnit "+c);
    }

    function repRetValIteration(_stream:AS):Void {
        m_send.push("var a:Array<Dynamic> = [];");
        m_send.push("for(i in 0...x.length) {");
        var c = _stream.shift();
        print(c+" repRetValIteration");
        while(c != "}" ) {
            repRetValUnit(_stream);
            c = _stream.shift();
        }
        _stream.splice(0, ":*]".length);
        m_send.push("a.push();");
        m_send.push("}");
    }

    function repRetValOption(_stream:AS):Void {
        var c = _stream.shift();
        print(c+" repRetValOption");
        while(c != ")") {
            repRetValUnit(_stream);
            c = _stream.shift();
        }
    }

    function getRead(_c:String, _id:String):String {
        var size = Std.parseInt(_c);
        return switch(size) {
            case 1:
                "Byte();";
            case 2:
                 "UInt16();";
            case 4:
                "Int31();";
            case 8:
                "(8);";
            default:
                "("+_id.charAt(0)+"siz.length);";
        }
    }

}
