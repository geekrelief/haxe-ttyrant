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
        var b = new BytesOutput();
        b.bigEndian = true;
        b.writeUInt16(51314);
        m_o.write(b.getBytes());
        var success = m_i.readByte();
        return (success == 0);
    }

    public function put(_k:String, _v:Bytes):Bool {
        m_o.writeUInt16(51216);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_v.length);
        m_o.writeString(_k);
        m_o.write(_v);
        return (m_i.readByte() == 0);
    }

    /*
    public function put(_k:String, _v:Bytes):Bool {
        var b = new BytesOutput();
        b.bigEndian = true;
        b.writeUInt16(51216);
        b.writeInt31(_k.length);
        b.writeInt31(_v.length);
        b.writeString(_k);
        b.write(_v);
        m_o.write(b.getBytes());
        var success:Int = m_i.readByte();
        return (success == 0);
    }
    */

    public function get(_k:String):Bytes {
        var b = new BytesOutput();
        b.bigEndian = true;
        b.writeUInt16(51248);
        b.writeInt31(_k.length);
        b.writeString(_k);
        m_o.write(b.getBytes());
        var success = m_i.readByte();
        var val:Bytes = null;
        if (success == 0) {
            var len = m_i.readInt31();
            val = m_i.read(len);
        }
        return val;
    }

}
