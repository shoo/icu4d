module icu4d.misc;


package(icu4d):

import std.encoding;
import bindbc.icu;


///
string toStringFromAscii(in char* s)
{
	import core.stdc.string: strlen;
	auto len = strlen(s);
	// ASCII only == UTF-8
	return s[0..len+1].idup[0..len];
}

///
const(char)* toAsciiCstr(in char[] s)
{
	return (*((&s[0]) + s.length) == '\0') ? s.ptr : (s ~ '\0').ptr;
}

///
class Icu4dEncodingException: EncodingException
{
	UErrorCode errorCode;
	this(UErrorCode err)
	{
		import std.conv;
		errorCode = err;
		super(err.to!string());
	}
	this(UErrorCode err, string msg)
	{
		errorCode = err;
		super(msg);
	}
}

///
UErrorCode icuEnforce(UErrorCode err)
{
	import std.exception;
	enforce(U_SUCCESS(err), new Icu4dEncodingException(err));
	return err;
}

///
UErrorCode icuEnforce(UErrorCode err, string msg)
{
	import std.exception;
	enforce(U_SUCCESS(err), new Icu4dEncodingException(err, msg));
	return err;
}
