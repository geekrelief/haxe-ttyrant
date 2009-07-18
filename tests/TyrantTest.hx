import ttyrant.Connection;

class Tests extends haxe.unit.TestCase {
    var m_c:Connection;
    public function new():Void {
        super();
    }
    
    override public function setup():Void {
        m_c = new Connection();
        m_c.connect("127.0.0.1", 1978);
        m_c.vanish();
    }

    override public function tearDown():Void {
        m_c.close();
    }

    public function at(_b:Bool, ?_c:haxe.PosInfos):Void {
        assertTrue(_b, _c);
    }

    public function af(_b:Bool, ?_c:haxe.PosInfos):Void {
        assertFalse(_b, _c);
    }

    public function ae<T>(_a:T, _b:T, ?_c:haxe.PosInfos):Void {
        assertEquals(_a, _b, _c);
    }

    public function tob(_str:String):Bytes {
        var bo = new haxe.io.BytesOutput();
        bo.writeString(_str);
        return bo.getBytes();
    }

    public function tos(_b:Bytes):String {
        var bi = new haxe.io.BytesInput(_b);
        return bi.readString(_b.length);
    }

    public function test_put() {
        // put overwrites
        at(m_c.put("hello", tob("world")));
        at(m_c.put("hello", tob("world!")));
    }

    public function test_get() {
        // empty value
        ae(m_c.get("hello"), null);

        // get existing value
        at(m_c.put("hello", tob("tyrant!")));
        ae(tos(m_c.get("hello")), "tyrant!");

    }

    public function test_putkeep() {
        // puts if does not exist
        at(m_c.putkeep("hello", tob("world")));
        af(m_c.putkeep("hello", tob("tyrant!")));
        ae(tos(m_c.get("hello")), "world");
    }

    public function test_putcat() {
        // cat value if present
        at(m_c.putkeep("hello", tob("Gina")));
        at(m_c.putcat("hello", tob(" Carano")));
        ae(tos(m_c.get("hello")), "Gina Carano");

        // otherwise create
        ae(m_c.get("hyper"), null);
        at(m_c.putcat("hyper", tob("shiny")));
        ae(tos(m_c.get("hyper")), "shiny");
    }
}

class TyrantTest {
    static function main() {
        var r = new haxe.unit.TestRunner();
        r.add(new Tests());
        r.run();
    }
}
