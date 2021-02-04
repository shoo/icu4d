module app;

import std;

import icu4d;

mixin registerICUScheme!"EUC-JP";
mixin registerICUScheme!"EUC-JP";
mixin registerICUScheme!"EUC-JP";

int main()
{
	auto textpart = "すこしぐらいはよいだろう。わたしの舌は大きくない。";
	auto textbuf = cast(ubyte[])std.file.read("../.testresources/euc-jp.txt");
	auto utfbuf  = decodeText!"EUC-JP"(textbuf);
	assert(utfbuf.canFind(textpart));
	
	auto sjistxt = encodeText!"EUC-JP"(textpart);
	assert(textbuf.canFind(sjistxt));
	assert(textbuf == utfbuf.encodeText!"EUC-JP"());
	
	auto utf16part = textpart.to!wstring;
	auto utf16buf = cast(const ubyte[])utf16part;
	assert(utf16part.encodeText!"UTF-8" == cast(const ubyte[])utf16buf.decodeText!"UTF-16LE"());
	return 0;
}
