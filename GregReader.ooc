import structs/[ArrayList, Stack]

/***
 * Convert utf-8 string
 */
extend ArrayList<UInt32>{
    /* ECMA-262, 5th ed., 7.8.4 */
    escape: func -> ArrayList<UInt32>{
        toNumber := func(c: UInt32) -> Int {
            if('0' <= c && c <= '9'){ return c - '0' }
            if('A' <= c && c <= 'F'){ return 10 + c - 'A' }
            if('a' <= c && c <= 'f'){ return 10 + c - 'a' }
            0
        }
        i := 0
        ret := ArrayList<UInt32> new()
        while(i < this size){
            if(this[i] as UInt32 == '\\'){
                i += 1
                match(this[i] as UInt32){
                    case 'x' =>
                        i += 1
                        oct := 0
                        j := 0
                        while(j < 2){
                            cc := this[i+j] as UInt32
                            if(('0' <= cc && cc <= '9') || \
                               ('A' <= cc && cc <= 'F') || \
                               ('a' <= cc && cc <= 'f')){
                                oct = oct * 16 + toNumber(cc)
                            } else {
                                break
                            }
                            j += 1
                        }
                        i += j
                        ret add(oct)
                    case 'u' | 'U' =>
                        i += 1
                        if(this[i] as UInt32 == '+') i += 1
                        oct := 0
                        j := 0
                        while(j < 6) {
                            cc := this[i+j] as UInt32
                            if(('0' <= cc && cc <= '9') || \
                               ('A' <= cc && cc <= 'F') || \
                               ('a' <= cc && cc <= 'f')){
                                oct = oct * 16 + toNumber(cc)
                            } else {
                                break
                            }
                            j += 1
                        }
                        i += j
                        ret add(oct)
                    case => 
                        cc := this[i] as UInt32
                        if('0' <= cc && cc <= '7'){
                            oct := 0
                            j := 0
                            while(j < 3) {
                                cc = this[i+j] as UInt32
                                if(('0' <= cc && cc <= '7')){
                                    oct = oct * 8 + toNumber(cc)
                                } else {
                                    break
                                }
                                j += 1
                            }
                            i += j
                            ret add(oct)
                        } else {
                            ret add( match(this[i] as UInt32){
                                case '\\' => '\\'
                                case '"' => '"'
                                case 't' => '\t'
                                case 'n' => '\n'
                                case 'f' => '\f'
                                case 'r' => '\r'
                                case => '\0'
                            } as UInt32 )
                            i += 1
                        }
                }
            } else {
                ret add(this[i] as UInt32)
                i += 1
            }
        }
        ret
    }

    /* ECMA-262, 5th ed., 7.8.5 */
    regExpEscape: func -> ArrayList<UInt32>{
        toNumber := func(c: UInt32) -> Int{
            if('0' <= c && c <= '9'){ return c - '0' }
            if('A' <= c && c <= 'F'){ return 10 + c - 'A' }
            if('a' <= c && c <= 'f'){ return 10 + c - 'a' }
            0
        }
        i := 0
        ret := ArrayList<UInt32> new()
        while(i < this size){
            if(this[i] as UInt32 == '\\'){
                i += 1
                match(this[i] as UInt32){
                    case 'x' =>
                        i += 1
                        oct := 0
                        j := 0
                        while(j < 2){
                            cc := this[i+j] as UInt32
                            if(('0' <= cc && cc <= '9') || \
                               ('A' <= cc && cc <= 'F') || \
                               ('a' <= cc && cc <= 'f')){
                                oct = oct * 16 + toNumber(cc)
                            } else {
                                break
                            }
                            j += 1
                        }
                        i += j
                        ret add(oct)
                    case 'u' =>
                        i += 1
                        oct := 0
                        j := 0
                        while(j < 6) {
                            cc := this[i+j] as UInt32
                            if(('0' <= cc && cc <= '9') || \
                               ('A' <= cc && cc <= 'F') || \
                               ('a' <= cc && cc <= 'f')){
                                oct = oct * 16 + toNumber(cc)
                            } else {
                                break
                            }
                            j += 1
                        }
                        i += j
                        ret add(oct)
                    case => 
                        cc := this[i] as UInt32
                        if('0' <= cc && cc <= '7'){
                            oct := 0
                            j := 0
                            while(j < 3) {
                                cc = this[i+j] as UInt32
                                if(('0' <= cc && cc <= '7')){
                                    oct = oct * 8 + toNumber(cc)
                                } else {
                                    break
                                }
                                j += 1
                            }
                            i += j
                            ret add(oct)
                        } else {
                            ret add( match(this[i] as UInt32){
                                case 'a' => '\a'
                                case 'b' => '\b'
                                case 'e' => 27 as Char
                                case 'f' => '\f'
                                case 'n' => '\n'
                                case 'r' => '\r'
                                case 't' => '\t'
                                case 'v' => '\v'
                                case => '\0'
                            } as UInt32)
                            i += 1
                        }
                }
            } else {
                ret add(this[i] as UInt32)
                i += 1
            }
        }
        ret
    }
}

/***
 * GregReadter is a special reader for reading source codes
 * It is usually initialized by a string, and convert string to utf-8 array automatically
 * The most important funciton is peek(n) func. It peek a string
 * without changing position.
 */
GregReader : class{
    buffer := ArrayList<UInt32> new()
    position: Int = 0
    posStack := Stack<Int> new()

    ////////////////////////////////////////////////////////////////////////////////////////
    /* See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.
    * Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>
    * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    * to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
    * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
    * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  */
    decodeUTF8: func(text: String) {
        ACCEPT := static const 0
        DECLINE := static const 1
        UTF8D := const [
          0 as UInt8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 00..1f
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 20..3f
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 40..5f
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 60..7f
          1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, // 80..9f
          7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, // a0..bf
          8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, // c0..df
          0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3, // e0..ef
          0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8, // f0..ff
          0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1, // s0..s0
          1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1, // s1..s2
          1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1, // s3..s4
          1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1, // s5..s6
          1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1, // s7..s8
          ]
        _state: Int32 = ACCEPT
        _codep: Int32 = 0
        for(i in 0..text size){
            byte := text[i] as UInt32
            type := UTF8D[(byte & 0xff) as UInt32] as UInt32
            _codep = (_state != ACCEPT) ? \
                  (byte & 0x0000003fu) | (_codep << 6) : (0x000000ff >> type) & (byte)
            if((_state = UTF8D[256+_state*16+type]) == 0){ buffer add(_codep) }
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////

    init: func(text: String) { decodeUTF8(text) }

    push: func { posStack push(position) }
    pop: func { position = popStack pop() }

    /** 
     * Count how many bytes a codepoint contains
     */
    bytes: func(c: UInt32) -> Int {
        if(c < 0x80 ) return 1
        else if(c < 0x800) return 2
        else if(c < 0x10000) return 3
        return 4
    }

    /**
     * convert a codepoint to utf-8 bytes
     */
    encodeUTF8: func(c: UInt32) -> String{
        if(c < 0x80){
           return (c as Char) toString()
        } else if(c < 0x800) {
            return (0xc0 | (c >> 6)) as Char toString() + ((0x80 | (c & 0x3F)) as Char)
        } else if(c < 0x10000) {
            return (0xe0 | (c >> 12)) as Char toString() + \
            ((0x80 | ((c >> 6) & 0x3F)) as Char) + \
            ((0x80 | (c & 0x3F)) as Char)
        } 
        return (0xf0 | (c >> 18)) as Char toString() + \
        ((0x80 | ((c >> 12) & 0x3F)) as Char) + \
        ((0x80 | ((c >> 6) & 0x3F)) as Char) + \
        ((0x80 | (c & 0x3F)) as Char)
    }

    encodeUTF8: func ~array (c: ArrayList<UInt32>) -> String{
        ret := ""
        for(i in 0..c size){
            ret += encodeUTF8(c[i])
        }
        ret
    }

    substring: func(start: Int, end: Int) -> String { encodeUTF8(buffer slice(start, end)) }

    validPos?: func -> Bool { position < buffer size }
    validPos: func(pos: Int) -> Int { 
        if(pos < 0) return 0 
        pos < buffer size ? pos : buffer size - 1
    }


    /***
     * Read as UInt32
     */
    peekUTF8: func -> UInt32 {
        if(!validPos?()) return 0
        buffer[validPos(position)]
    }

    peekUTF8: func ~str (n: Int) -> ArrayList<UInt32> {
        if(!validPos?()) return ArrayList<UInt32> new()
        buffer slice(position, validPos(position+n))
    }

    readUTF8: func -> UInt32 {
        if(!validPos?()) return 0
        buffer[validPos(position)]
        position += 1
    }

    readUTF8: func ~str (n: Int) -> ArrayList<UInt32> {
        if(!validPos?()) return ArrayList<UInt32> new()
        buffer slice(position, validPos(position+n))
        position += 1
    }


    /***
     * Read as Char
     */

    peek: func -> String{
        if(!validPos?()) return ""
        encodeUTF8(buffer[validPos(position)])
    }

    peek: func ~str (n: Int) -> String {
        if(!validPos?()) return ""
        substring(position, validPos(position+n))
    }

    /***
     * Read from a position without changing current cursor
     */
    peekFrom: func(pos: Int, len: Int) -> String{
        if(pos < 0) pos = 0
        if(len < 0) return ""
        substring(pos, validPos(pos+len))
    }

    /***
     * Read from a position 
     * also changing current cursor
     */
    readFrom: func(pos: Int, len: Int) -> String{
        if(pos < 0) pos = 0
        if(len < 0) return ""
        s := substring(pos, validPos(pos+len))
        position = validPos(pos+len)
        s
    }

    /***
     * Goto position
     */
    seek: func(pos: Int) { position = pos }

    /***
     * Read a character
     */
    read: func -> String {
        c := peek()
        if(c size == 1) position += 1
        c
    }

    /***
     * Read a string
     */
    read: func ~str (n: Int) -> String {
        s := peek(n)
        position += s size
        s
    }

    /***
     * Go back for n characters
     * Notice that n is not bytes but real characters in utf-8
     */
    rewind: func (n: Int = 1) {
        position -= n
        if(position < 0) position = 0
    }

    /***
     * Read untile the first match of c (include c) or reach the number limits
     * if n == -1, the number is unlimited
     */
    readUntil: func(c: UInt32, n: Int = -1) -> String {
        count := 0
        ret := ArrayList<UInt> new()
        while ( position < buffer size && (n == -1 || count < n) && buffer[position] != c ){
            ret add(buffer[position])
            count += 1
            position += 1
        }
        ret add(buffer[position])
        position += 1
        encodeUTF8(ret)
    }

    /***
     * Read untile the first match of c (include c) or reach the number limits
     * if n == -1, the number is unlimited
     */
    readUntil: func ~string (c: String, n: Int = -1) -> String {
        count := 0
        ret := ArrayList<UInt> new()
        while ( position < buffer size && (n == -1 || count < n) && (ret size < c size || substring(position - c size, position) != c) ){
            ret add(buffer[position])
            count += 1
            position += 1
        }
        ret add(buffer[position])
        position += 1
        encodeUTF8(ret)
    }

}
