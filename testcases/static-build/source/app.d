import std;

import icu4d;

mixin registerICUScheme!"Shift_JIS";

int main()
{
	auto textpart = "ほんとうに人間はいいものかしら。ほんとうに人間はいいものかしら";
	auto textbuf = cast(ubyte[])std.file.read("../.testresources/sjis.txt");
	auto utfbuf  = decodeText!"Shift_JIS"(textbuf);
	assert(utfbuf.canFind(textpart));
	
	auto sjistxt = encodeText!"Shift_JIS"(textpart);
	assert(textbuf.canFind(sjistxt));
	assert(textbuf == utfbuf.encodeText!"Shift_JIS"());
	
	auto utf16part = textpart.to!wstring;
	auto utf16buf = cast(const ubyte[])utf16part;
	assert(utf16part.encodeText!"UTF-8" == cast(const ubyte[])utf16buf.decodeText!"UTF-16LE"());
	return 0;
}
