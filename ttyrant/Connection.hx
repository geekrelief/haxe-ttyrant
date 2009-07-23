package ttyrant;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import math.BigInteger;

class Connection {

    /* Options */
                                            // ext options
    public static var RDBXOLCKREC = 1 << 0; // record locking
    public static var RDBXOLCKGLB = 1 << 1; // global locking

                                            // restore options
    public static var RDBROCHKCON = 1 << 0; // consistency checking

                                            // misc operations options
    public static var RDBMONOULOG = 1 << 0; // omisssion of update log

    var m_sock: neko.net.Socket;
    var m_i:neko.net.SocketInput;
    var m_o:neko.net.SocketOutput;
    var m_padding:Bytes;
    static var B1e3:BigInteger = BigInteger.ofInt(1000);
    static var B1e6:BigInteger = BigInteger.ofInt(1000000);
    
    public function new(?_host:String, ?_port:Int = 1978){
        m_sock = new neko.net.Socket();
        m_i = m_sock.input;
        m_o = m_sock.output;
        m_i.bigEndian = true;
        m_o.bigEndian = true;
        var bb = new BytesBuffer();
        for(i in 0...8) {
            bb.addByte(0);
        }
        m_padding = bb.getBytes();
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

    public function host(): {port:Int, host:neko.net.Host} {
        return m_sock.host();
    }

    public function peer(): {port:Int, host:neko.net.Host} {
        return m_sock.peer();
    }

    public function toMicro(_f:Float):BigInteger {
        var i = Math.floor(_f);
        var f = Std.int((_f % i) * 1e+6);
        var bi = BigInteger.ofInt(i).mul(B1e6);
        return bi.add(BigInteger.ofInt(f));
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

    /*
        iterinit: for the function `tcrdbiterinit'
        The function `tcrdbiterinit' is used in order to initialize the iterator of a remote database object.
        If successful, the return value is true, else, it is false.
        The iterator is used in order to access the key of every record stored in a database.
     */
    public function iterinit():Bool {
        m_o.writeUInt16(51280);
        return (m_i.readByte() == 0);
    }

    /*
        iternext: for the function `tcrdbiternext'
        The function `tcrdbiternext' is used in order to get the next key of the iterator of a remote database object.
        If successful, the return value is a key, else it is null.
    */
    public function iternext():String {
        m_o.writeUInt16(51281);
        var val:String = null;
        if((m_i.readByte() == 0)) {
            val = m_i.readString(m_i.readInt31());
        }
        return val;
    }

    /*
        fwmkeys: for the function `tcrdbfwmkeys'
        The function `tcrdbfwmkeys' is used in order to get forward (prefix) matching keys in a remote database object.
        The return value is an Array of the corresponding keys. 
        This function does not fail. It returns an empty list even if no key corresponds.
    */
    public function fwmkeys(_p:String, _max:Int):Array<String> {
        m_o.writeUInt16(51288);
        m_o.writeInt31(_p.length);
        m_o.writeInt31(_max);
        m_o.writeString(_p);
        var val:Array<String> = [];
        if(m_i.readByte() == 0) {
            var knum = m_i.readInt31();
            for(i in 0...knum) {
                val.push(m_i.readString(m_i.readInt31()));
            }
        }
        return val;
    }

    /*
        addint: for the function `tcrdbaddint'
        The function `tcrdbaddint' is used in order to add an integer to a record in a remote database object.
        If successful, the return value is the summation value, else, it is `INT_MIN'.
        If the corresponding record exists, the value is treated as an integer and is added to. 
        If no record corresponds, a new record of the additional value is stored.
    */
    public function addint(_k:String, _n:Int):Int {
        m_o.writeUInt16(51296);
        m_o.writeInt31(_k.length);
        m_o.writeInt31(_n);
        m_o.writeString(_k);
        var val:Int = 0;
        if(m_i.readByte() == 0) {
            val = m_i.readInt31();
        }
        return val;
    }

    /*
        The function `tcrdbadddouble' is used in order to add a real number to a record in a remote database object.
        If successful, the return value is the sum, else null.
        If the corresponding record exists, the value is treated as a real number and is added to. If no record corresponds, a new record of the additional value is stored.
    */

    public function adddouble(_k:String, _f:Float):Float {
        var i = Math.floor(_f);
        var bi = BigInteger.ofInt(i);
        var f = Std.int((_f % i) * 1e+9);
        var bf = BigInteger.ofInt(f).mul(B1e3);

        m_o.writeUInt16(51297);
        m_o.writeInt31(_k.length);
        m_o.writeBytes(m_padding, 0, 8-bi.toBytes().length);
        m_o.write(bi.toBytes());
        m_o.writeBytes(m_padding, 0, 8-bf.toBytes().length);
        m_o.write(bf.toBytes());
        m_o.writeString(_k);
        var val:Float = null;
        if(m_i.readByte() == 0) {
            var vi = BigInteger.ofBytes(m_i.read(8)).toInt();
            var vf = BigInteger.ofBytes(m_i.read(8)).div(B1e3).toInt()*1e-9;
            val = vi+vf;
        }
        return val;
    }


    /*
        The function `tcrdbext' is used in order to call a function of the script language extension.
        _n: specifies the function name.
        _o: specifies options by bitwise-or: `RDBXOLCKREC' for record locking, `RDBXOLCKGLB' for global locking.
        If successful, the return value is a Bytes object, else, it is null.
    */
    public function ext(_n:String, ?_k:String = null, ?_v:Bytes = null, ?_o:Int = 0):Bytes {
        m_o.writeUInt16(51304);
        m_o.writeInt31(_n.length);
        m_o.writeInt31(_o);
        m_o.writeInt31((_k != null) ? _k.length : 0);
        m_o.writeInt31((_v != null) ? _v.length : 0);
        m_o.writeString(_n);
        if(_k != null) m_o.writeString(_k);
        if(_v != null) m_o.write(_v);
        var val:Bytes = null;
        if(m_i.readByte() == 0) {
            val = m_i.read(m_i.readInt31());
        }
        return val;
    }

    /*
        sync: for the function `tcrdbsync'
        The function `tcrdbsync' is used in order to synchronize updated contents of a remote database object with the file and the device.
        If successful, the return value is true, else, it is false.
    */
    public function sync():Bool {
        m_o.writeUInt16(51312);
        return (m_i.readByte() == 0);
    }

    /* 
        optimize: for the function `tcrdboptimize'
        The function `tcrdboptimize' is used in order to optimize the storage of a remove database object.
        _p: string of tuning parameters
        If successful, the return value is true, else, it is false.
    */
    public function optimize(_p:String):Bool {
        m_o.writeUInt16(51313);
        m_o.writeInt31(_p.length);
        m_o.writeString(_p);
        return (m_i.readByte() == 0);
    }

    /*
        vanish: for the function `tcrdbvanish'
        The function `tcrdbvanish' is used in order to remove all records of a remote database object.
        If successful, the return value is true, else, it is false.
    */
    public function vanish():Bool {
        m_o.writeUInt16(51314);
        return (m_i.readByte() == 0);
    }

    /*
        copy: for the function `tcrdbcopy'
        The function `tcrdbcopy' is used in order to copy the database file of a remote database object.
        _p: specifies the path of the destination file. If it begins with `@', the trailing substring is executed as a command line.
        If successful, the return value is true, else, it is false. False is returned if the executed command returns non-zero code.
        The database file is assured to be kept synchronized and not modified while the copying or executing operation is in progress. 
        So, this function is useful to create a backup file of the database file.
        This function fails and has no effect for on-memory database.
    */
    public function copy(_p:String):Bool {
        m_o.writeUInt16(51315);
        m_o.writeInt31(_p.length);
        m_o.writeString(_p);
        return (m_i.readByte() == 0);
    }

    /*
        restore: for the function `tcrdbrestore'
        The function `tcrdbrestore' is used in order to restore the database file of a remote database object from the update log.
        _p: specifies the path of the update log directory.
        _t: specifies the beginning time stamp in seconds.
        _o: specifies options by bitwise-or: `RDBROCHKCON' for consistency checking.
        If successful, the return value is true, else, it is false.
    */
    public function restore(_p:String, _t:Float, _o:Int):Bool {
        m_o.writeUInt16(51316);
        m_o.writeInt31(_p.length);
        var bt = toMicro(_t);
        m_o.writeBytes(m_padding, 0, 8-bt.toBytes().length);
        m_o.write(bt.toBytes());
        m_o.writeInt31(_o);
        m_o.writeString(_p);
        return (m_i.readByte() == 0);
    }

    /*
        setmst: for the function `tcrdbsetmst'
        The function `tcrdbsetmst' is used in order to set the replication master of a remote database object.
        _h: specifies the name or the address of the server. If it is `null', replication of the database is disabled.
        _p: specifies the port number.
        _t: specifies the beginning timestamp in seconds.
        _o: specifies options by bitwise-or: `RDBROCHKCON' for consistency checking.
        If successful, the return value is true, else, it is false. 
    */
    public function setmst(_h:String, _p:Int, _t:Float, _o:Int):Bool {
        m_o.writeUInt16(51320);
        m_o.writeInt31((_h != null) ? _h.length : 0);
        m_o.writeInt31(_p);
        var bt = toMicro(_t);
        m_o.writeBytes(m_padding, 0, 8-bt.toBytes().length);
        m_o.write(bt.toBytes());
        m_o.writeInt31(_o);
        if(_h != null) m_o.writeString(_h);
        return (m_i.readByte() == 0);
    }

    /*
        rnum: for the function `tcrdbrnum'
        The function `tcrdbrnum' is used in order to get the number of records of a remote database object.
    */
    public function rnum():BigInteger {
        m_o.writeUInt16(51328);
        var val:BigInteger = null;
        if(m_i.readByte() == 0) {
            val = BigInteger.ofBytes(m_i.read(8));
        }
        return val;
    }

    /*
        size: for the function `tcrdbsize'
        The function `tcrdbsize' is used in order to get the size of the database of a remote database object.
        The return value is the size of the database or 0 if the object does not connect to any database server.
    */
    public function size():BigInteger {
        m_o.writeUInt16(51329);
        var val:BigInteger = BigInteger.ofInt(0);
        if(m_i.readByte() == 0) {
            val = BigInteger.ofBytes(m_i.read(8));
        }
        return val;
    }

    /*
        stat: for the function `tcrdbstat'
        The function `tcrdbstat' is used in order to get the status string of the database of a remote database object.
        The return value is a Hash filled with the status of the db, it is null if not connected to any database.
        //The message format is TSV. The first field of each line means the parameter name and the second field means the value.
    */
    public function stat():Hash<String> {
        m_o.writeUInt16(51336);
        var val:Hash<String> = null;
        if(m_i.readByte() == 0) {
            val = new Hash();
            var stat = m_i.readString(m_i.readInt31());
            var astat = stat.split("\n");
            for(s in astat) {
                var kv = s.split("\t");
                val.set(kv[0], kv[1]);
            }
        }
        return val;
    }

    /*
        misc: for the function `tcrdbmisc'
        The function `tcrdbmisc' is used in order to call a versatile function for miscellaneous operations of a remote database object.
        _n: specifies the name of the function. 
            All databases support "put", "out", "get", "putlist", "outlist", and "getlist". 
            "put" is to store a record. It receives a key and a value, and returns an empty list. 
            "out" is to remove a record. It receives a key, and returns an empty list. 
            "get" is to retrieve a record. It receives a key, and returns a list of the values. 
            "putlist" is to store records. It receives keys and values one after the other, and returns an empty list. 
            "outlist" is to remove records. It receives keys, and returns an empty list. 
            "getlist" is to retrieve records. It receives keys, and returns keys and values of corresponding records one after the other.
        _o: specifies options by bitwise-or: `RDBMONOULOG' for omission of the update log.
        _ab: specifies the Bytes of the argument list.
        If successful, the return value is a list object of the result. `NULL' is returned on failure.
    */
    public function misc(_n:String, _o:Int, _alen:Int, _ab:Bytes):Array<Bytes> {
        m_o.writeUInt16(51344);
        m_o.writeInt31(_n.length);
        m_o.writeInt31(_o);
        m_o.writeInt31(_alen);
        m_o.writeString(_n);
        m_o.write(_ab);
        var val:Array<Bytes> = null;
        if(m_i.readByte() == 0) {
            var rnum = m_i.readInt31();
            val = [];
            for(i in 0...rnum) {
                val.push(m_i.read(m_i.readInt31()));
            }
        }
        return val;
    }
}
