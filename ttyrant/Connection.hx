package ttyrant;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class Connection {
    private var m_sock: neko.net.Socket;
    private var m_i:neko.net.SocketInput;
    private var m_o:neko.net.SocketOutput;
    
    public function new(?_host:String, ?_port:Int = 1978){
        m_sock = new neko.net.Socket();
        m_i = m_sock.input;
        m_o = m_sock.output;
        m_i.bigEndian = true;
        m_o.bigEndian = true;
        if(_host != null)
            connect(_host, _port);
    }

    public function connect(_host:String, _port:Int){
        m_sock.connect(new neko.net.Host(_host), _port);
    }

    public function close():Void {
        m_sock.close();
    }

    public function setTimeout(_timeout:Float){
        m_sock.setTimeout(_timeout);
    }

    
    public function vanish():Bool {
        m_o.writeUInt16(51314);
        return (m_i.readByte() == 0);
    }

    /*
        put: for the function `tcrdbput'
        The function `tcrdbput' is used in order to store a record into a remote database object.
        If successful, the return value is true, else, it is false.
        If a record with the same key exists in the database, it is overwritten.
    */
    public function put(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51216);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    /*
        putkeep: for the function `tcrdbputkeep'
        The function `tcrdbputkeep' is used in order to store a new record into a remote database object.
        If successful, the return value is true, else, it is false.
        If a record with the same key exists in the database, this function has no effect.
    */
    public function putkeep(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51217);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    /* 
        putcat: for the function `tcrdbputcat'
        The function `tcrdbputcat' is used in order to concatenate a value at the end of the existing record in a remote database object.
        If successful, the return value is true, else, it is false.
        If there is no corresponding record, a new record is created.
    */
    public function putcat(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51218);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    /*
        putshl: for the function `tcrdbputshl'
        The function `tcrdbputshl' is used in order to concatenate a value at the end of the existing record and shift it to the left.
        If successful, the return value is true, else, it is false.
        If there is no corresponding record, a new record is created.
    */
    public function putshl(_k:String, _v:Bytes, _w:Int):Bool {
        m_o.writeUInt16(51219);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeInt31(_w);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    /*
        putnr: for the function `tcrdbputnr'
        The function `tcrdbputnr' is used in order to store a record into a remote database object without response from the server.
        If a record with the same key exists in the database, it is overwritten.
    */
    public function putnr(_k:String, _v:Bytes):Void {
        m_o.writeUInt16(51224);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
    }

    /*
        out: for the function `tcrdbout'
        The function `tcrdbout' is used in order to remove a record of a remote database object.
        If successful, the return value is true, else, it is false.
    */
    public function out(_k:String):Bool {
        m_o.writeUInt16(51232);
        m_o.writeInt31(_k.length);
        m_o.writeString(_k);
        return (m_i.readByte() == 0);
    }

    /*
        get: for the function `tcrdbget'
        The function `tcrdbget' is used in order to retrieve a record in a remote database object.
        If successful, the return value is stored in a Bytes object, else, it is null.
    */
    public function get(_k:String):Bytes {
        m_o.writeUInt16(51248);
        m_o.writeInt31(_k.length);
        m_o.writeString(_k);
        var val:Bytes = null;
        if((m_i.readByte() == 0))
            val = m_i.read(m_i.readInt31());
        return val;
    }

    /*
        mget: for the function `tcrdbget3'
        The function `tcrdbget3' is used in order to retrieve records in a remote database object.
        The return value is an Array of key, value pairs with length 0 or greater.
    */
    public function mget(_ks:Array<String>):Array<{k:String, v:Bytes}> {
        m_o.writeUInt16(51249);
        m_o.writeInt31(_ks.length);
        for(k in _ks)  {
            m_o.writeInt31(k.length);
            m_o.writeString(k);
        }
        var val:Array<{k:String, v:Bytes}> = null;
        if(m_i.readByte() == 0) {
            val = [];
            var rnum = m_i.readInt31();
            for(i in 0...rnum) {
                var ksiz = m_i.readInt31();
                var vsiz = m_i.readInt31();
                var kbuf = m_i.readString(ksiz);
                var vbuf = m_i.read(vsiz);
                val.push({k:kbuf, v:vbuf});
            }
        }
        return val;
    }

    /*
        vsiz: for the function `tcrdbvsiz'
        The function `tcrdbvsiz' is used in order to get the size of the value of a record in a remote database object.
        If successful, the return value is the size of the value of the corresponding record, else, it is -1.
    */
    public function vsiz(_k:String):Int {
        m_o.writeUInt16(51256);
        m_o.writeInt31(_k.length);
        m_o.writeString(_k);
        var val:Int = -1;
        if(m_i.readByte() == 0) {
            val = m_i.readInt31();
        }
        return val;
    }

}
