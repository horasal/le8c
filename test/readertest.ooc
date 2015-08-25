use le8c
import GregReader

reader := GregReader new("柿くえば鐘がなるなり法隆寺")
reader peek(100) println()
reader = GregReader new("我爱北京天安门")
reader peek(100) println()
reader = GregReader new("Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.")
reader peek(100) println()
reader = GregReader new("\u011e\u011f\\u011e\\u011f")
reader buffer = reader buffer escape()
reader peek(100) println()
