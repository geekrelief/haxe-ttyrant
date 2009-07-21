import ttyrant.Connection;
import math.BigInteger;

class Tests extends haxe.unit.TestCase {
    var m_c:Connection;
    public function new():Void {
        super();
    }
    
    override public function setup():Void {
        m_c = new Connection();
        m_c.connect("127.0.0.1", 19789);
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

    public function fs(_str:String):Bytes {
        var bo = new haxe.io.BytesOutput();
        bo.writeString(_str);
        return bo.getBytes();
    }

    public function fi(_v:Int):Bytes {
        var bo = new haxe.io.BytesOutput();
        bo.writeInt31(_v);
        return bo.getBytes();
    }

    public function tos(_b:Bytes):String {
        var bi = new haxe.io.BytesInput(_b);
        return bi.readString(_b.length);
    }

    public function toi(_b:Bytes):Int {
        var bi = new haxe.io.BytesInput(_b);
        return bi.readInt31();
    }

    public function test_put() {
        // put overwrites
        at(m_c.put("hello", fs("world")));
        at(m_c.put("hello", fs("world!")));
    }

    public function test_get() {
        // empty value
        ae(m_c.get("hello"), null);

        // get existing value
        at(m_c.put("hello", fs("tyrant!")));
        ae(tos(m_c.get("hello")), "tyrant!");

    }

    public function test_putkeep() {
        // puts if does not exist
        at(m_c.putkeep("hello", fs("world")));
        af(m_c.putkeep("hello", fs("tyrant!")));
        ae(tos(m_c.get("hello")), "world");
    }

    public function test_putcat() {
        // cat value if present
        at(m_c.putkeep("hello", fs("Gina")));
        at(m_c.putcat("hello", fs(" Carano")));
        ae(tos(m_c.get("hello")), "Gina Carano");

        // otherwise create
        ae(m_c.get("hyper"), null);
        at(m_c.putcat("hyper", fs("shiny")));
        ae(tos(m_c.get("hyper")), "shiny");
    }

    public function test_putshl() {
        // put with shift left
        at(m_c.putshl("rec", fs("0001"), 4));
        at(m_c.putshl("rec", fs("1000"), 8));
        ae(tos(m_c.get("rec")), "00011000");
    }

    public function test_putnr() {
        // put no response
        m_c.putnr("project", fs("a-ko"));
        ae(tos(m_c.get("project")), "a-ko");
    }

    public function test_out() {
        // delete value
        m_c.put("a", fs("b"));
        ae(tos(m_c.get("a")), "b");
        m_c.out("a");
        ae(m_c.get("a"), null);
    }

    public function test_mget() {
        // multi-get
        m_c.put("a", fs("1"));
        m_c.put("b", fs("2"));
        m_c.put("c", fs("3"));
        m_c.put("d", fs("4"));
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
        // value size
        m_c.put("e", fs("2.71828183"));
        ae(m_c.vsiz("e"), "2.71828183".length);
        ae(m_c.vsiz("f"), -1);
    }

    public function test_iterinit() {
        // iterator init
        at(m_c.iterinit());

        m_c.put("a", fs("1"));
        at(m_c.iterinit());
    }

    public function test_iternext() {
        // iterator next
        at(m_c.iterinit());
        ae(m_c.iternext(), null);

        m_c.put("a", fs("1"));
        at(m_c.iterinit());
        ae(m_c.iternext(), "a");
        ae(m_c.iternext(), null);
    }

    public function test_fwmkeys() {
        // forward (prefix) matching
        m_c.put("dev_1", fs("1"));
        m_c.put("dev_2", fs("1"));
        m_c.put("dev_3", fs("1"));
        m_c.put("pro_1", fs("1"));
        m_c.put("pro_2", fs("1"));
        m_c.put("pro_3", fs("1"));

        var a = m_c.fwmkeys("dev", 10);
        ae(a.length, 3);
        ae(a[0], "dev_1");
        ae(a[1], "dev_2");
        ae(a[2], "dev_3");
    }

    public function test_addint() {
        // add ints
        at(m_c.put("val_1", fi(10)));
        ae(toi(m_c.get("val_1")), 10);
        ae(m_c.addint("val_1", 1), 11);
    }


    public function test_adddouble() {
        m_c.adddouble("a", 1.234);
        ae(m_c.adddouble("a", 1.235), 2.469);
    }

    /* run ttserver -ext test.lua */
    public function test_ext() {
        ae(tos(m_c.ext("fibonacci","1")), "1");
        ae(tos(m_c.ext("fibonacci","4")), "3");
        ae(tos(m_c.ext("fibnext")), "1");
        ae(tos(m_c.ext("fibnext")), "1");
        ae(tos(m_c.ext("fibnext")), "2");
        ae(tos(m_c.ext("fibnext")), "3");
        ae(tos(m_c.ext("fibnext")), "5");
    }
    

    public function test_sync() {
        // sync to file
        at(m_c.sync());
    }

    public function test_optimize() {
        at(m_c.optimize(""));
        at(m_c.optimize("#bnum=1024"));
        at(m_c.optimize(""));
    }

    public function test_copy() {
        // copy db to file
        m_c.put("a", fs("1"));
        //af(m_c.copy("test_run/store.backup")); // if on memory false
        at(m_c.copy("test_run/store.backup")); // if on disk true
    }

    public function test_restore() {
        // restore from update log in ulog-back
        ae(m_c.get("one"), null);
        at(m_c.restore("ulog-back", 1.0, 0));
        ae(tos(m_c.get("one")), "first");
    }

    /*
    public function test_setmst() {

    }
    */

    public function test_rnum() {
        // number of records
        m_c.put("a", fs("1"));
        ae(m_c.rnum().compare(BigInteger.ofInt(1)), 0);
    }

    public function test_size() {
        // size of db
        ae(m_c.size().compare(BigInteger.ofInt(0)), 1);
    }

    public function test_stat() {
        at(m_c.stat().get("os") == "Linux");
    }
}

class TyrantTest {
    static function main() {
        var r = new haxe.unit.TestRunner();
        r.add(new Tests());
        r.run();
    }
}
