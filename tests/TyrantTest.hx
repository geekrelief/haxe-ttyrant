import ttyrant.Connection;

class Tests extends haxe.unit.TestCase {
    var m_c:Connection;
    public function new():Void {
        super();
        m_c = new Connection();
    }
    
    override public function setup():Void {
        m_c.connect("127.0.0.1", 1978);
        m_c.vanish();
    }

    override public function tearDown():Void {
        m_c.close();
    }

    public function stringBytes(_str:String):Bytes {
        var bo = new haxe.io.BytesOutput();
        bo.writeString(_str);
        return bo.getBytes();
    }

    public function test_put() {
        assertTrue(m_c.put("hello", stringBytes("world")));
    }
}

class TyrantTest {
    static function main() {
        var r = new haxe.unit.TestRunner();
        r.add(new Tests());
        r.run();
    }
}
