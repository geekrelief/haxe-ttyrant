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

    public function put(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51216);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    public function putkeep(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51217);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    public function putcat(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51218);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

/*
    public function putshl(_k:String):Bool {
        m_o.writeUInt16(51219);
        m_o.writeInt31(_k);
        m_o.writeInt31(_v);
        m_o.writeInt31(_w);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }
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
}
