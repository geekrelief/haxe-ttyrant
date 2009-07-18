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

    public function test_putshl() {
        // put with shift left
        at(m_c.putshl("rec", tob("0001"), 4));
        at(m_c.putshl("rec", tob("1000"), 8));
        ae(tos(m_c.get("rec")), "00011000");
    }

    public function test_putnr() {
        m_c.putnr("project", tob("a-ko"));
        ae(tos(m_c.get("project")), "a-ko");
    }

    public function test_out() {
        m_c.put("a", tob("b"));
        ae(tos(m_c.get("a")), "b");
        m_c.out("a");
        ae(m_c.get("a"), null);
    }

    public function test_mget() {
        m_c.put("a", tob("1"));
        m_c.put("b", tob("2"));
        m_c.put("c", tob("3"));
        m_c.put("d", tob("4"));
        var keys = ["a", "b", "c", "d", "e", "f"];
        var pairs = m_c.mget(keys);

        ae(pairs.length, 4);

        ae(pairs[0].k, "a");
        ae(tos(pairs[0].v), "1");
        ae(pairs[1].k, "b");
        ae(tos(pairs[1].v), "2");
        ae(pairs[2].k, "c");
        ae(tos(pairs[2].v), "3");
        ae(pairs[3].k, "d");
        ae(tos(pairs[3].v), "4");

        pairs = m_c.mget([]);
        ae(pairs.length, 0);

        pairs = m_c.mget(["abc"]);
        ae(pairs.length, 0);
    }

    public function test_vsiz() {
        m_c.put("e", tob("2.71828183"));
        ae(m_c.vsiz("e"), "2.71828183".length);
        ae(m_c.vsiz("f"), -1);
    }
}

class TyrantTest {
    static function main() {
        var r = new haxe.unit.TestRunner();
        r.add(new Tests());
        r.run();
    }
}
