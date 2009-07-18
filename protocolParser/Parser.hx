import math.BigInteger;
class Parser {

    var m_fname:String;

    public static function main() {
                var p = new Parser("tyrant_protocol.txt");
        p.run();
    }

    public function new(_fname:String) {
        m_fname = _fname;
    }

    public function run() {
        var contents:String = neko.io.File.getContent(m_fname);
        var lines = contents.split("\n");
        var method:String = "";
        var request:String = "";
        var magic:String = "";
        var response:String = "";

        var pmethods:Array<PMethod> = [];
        for(line in lines) {
            var parts = [];
            var header = "";
            var data = "";

            if(line.length > 0) {
                parts = line.split("|");
                header = StringTools.trim(parts[0]);
                data = StringTools.trim(parts[1]);
            }

            switch(header) {
                case "Method":
                    method = data;
                case "Request":
                    request = data;
                case "Magic":
                    magic = data;
                case "Response":
                    response = data;
                default:
                    //trace(method+" "+magic+" "+request+" "+response);
                    pmethods.push(new PMethod(method, magic, request, response)); 
            }
        }

        var f = neko.io.File.write("methods.hx", false);
        for(p in pmethods) {
            f.writeString(p.send());
        }
        f.flush();
        f.close();
    }
}
