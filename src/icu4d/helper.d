/*******************************************************************************
 * Helper of encode/decode
 */
module icu4d.helper;

///
@system unittest
{
	import icu4d;
	// register
	EncodingScheme.register!(ICUEncodingSchemeImpl!"Shift_JIS");
	
	auto textpart = "ごん、お前だったのか。いつも栗をくれたのは";
	auto sjistext  = textpart.encodeText!"Shift_JIS"();
	auto utf16text = textpart.encodeText!"UTF-16LE"();
	assert(sjistext.decodeText!"Shift_JIS"() == utf16text.decodeText!"UTF-16LE"());
}


import std.encoding;
import std.traits;
import std.range;

import bindbc.icu;
import icu4d.scheme;


///
void decodeText(Range)(const(ubyte)[] src, auto ref Range dst, string charsetName = null)
if (!isSomeString!Range && isOutputRange!(Range, dchar))
{
	import std.exception;
	auto scheme = EncodingScheme.create(charsetName);
	assert(scheme, "EncodingScheme must register.");
	if (auto icuScheme = cast(ICUEncodingScheme)scheme)
	{
		icuScheme.decodeSequence(src, dst);
	}
	else
	{
		while (src.length > 0)
			put(dst, scheme.decode(src));
	}
}
/// ditto
void decodeText(Str)(in ubyte[] src, ref Str dst, string charsetName = null)
if (isSomeString!Str)
{
	import std.array;
	auto app = appender!Str;
	decodeText(src, app, charsetName);
	dst = app.data;
}
/// ditto
string decodeText(in ubyte[] src, string charsetName = null)
{
	string ret;
	decodeText(src, ret, charsetName);
	return ret;
}
/// ditto
auto decodeText(string charsetName, Args...)(auto ref Args args)
{
	return decodeText(args, charsetName);
}

///
alias fromMBS = decodeText;

///
void encodeText(Src, Range)(Src src, auto ref Range dst, string charsetName = null)
if (isSomeString!Src && isOutputRange!(Range, ubyte))
{
	auto scheme = EncodingScheme.create(charsetName);
	assert(scheme, "EncodingScheme must register.");
	if (auto icuScheme = cast(ICUEncodingScheme)scheme)
	{
		icuScheme.encodeSequence(src, dst);
	}
	else
	{
		ubyte[512] buf;
		foreach (dchar c; src)
			put(dst, buf[0..scheme.encode(c, buf)]);
	}
}
/// ditto
void encodeText(Str)(Str src, ref immutable(ubyte)[] dst, string charsetName = null)
if (isSomeString!Str)
{
	auto app = appender!(immutable(ubyte)[]);
	encodeText(src, app, charsetName);
	dst = app.data;
}
/// ditto
immutable(ubyte)[] encodeText(Str)(Str src, string charsetName = null)
if (isSomeString!Str)
{
	auto app = appender!(immutable(ubyte)[]);
	encodeText(src, app, charsetName);
	return app.data;
}
/// ditto
auto encodeText(string charsetName, Args...)(auto ref Args args)
{
	return encodeText(args, charsetName);
}

///
alias toMBS = encodeText;
