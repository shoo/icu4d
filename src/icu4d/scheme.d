module icu4d.scheme;

public import std.encoding;
import std.range;
import std.traits;

import bindbc.icu;

import icu4d.misc;

version (BindBC_ICU_Dynamic)
{
	private import core.atomic: atomicOp;
	private shared size_t _instanceCnt;
}

///
abstract class ICUEncodingScheme: EncodingScheme
{
private:
	string _charsetName;
	const(char)* _charsetNameCstr;
	UConverter* _converter;
public:
	///
	this(string charsetName)
	{
		version (BindBC_ICU_Dynamic)
		{
			if (_instanceCnt.atomicOp!"+="(1) == 1)
			{
				if (loadIcu() != IcuSupport.icu)
					throw new EncodingException("Failed to load the library");
			}
		}
		_charsetName = charsetName;
		_charsetNameCstr = charsetName.toAsciiCstr();
		auto status = U_ZERO_ERROR;
		_converter = ucnv_open(_charsetNameCstr, &status);
		icuEnforce(status);
	}
	
	///
	~this()
	{
		ucnv_close(_converter);
		version (BindBC_ICU_Dynamic)
		{
			if (_instanceCnt.atomicOp!"-="(1) == 0)
				unloadIcu();
		}
	}
	
	///
	override string toString() const
	{
		return _charsetName;
	}
	
	///
	override string[] names() const
	{
		auto status = U_ZERO_ERROR;
		auto cnt = ucnv_countAliases(_charsetNameCstr, &status);
		icuEnforce(status);
		
		auto pointers = new char*[cnt];
		ucnv_getAliases(_charsetNameCstr, pointers.ptr, &status);
		icuEnforce(status);
		
		string[] ret;
		foreach (i; 0..cnt)
			ret ~= toStringFromAscii(pointers[i]);
		return ret;
	}
	
	///
	override bool canEncode(dchar c) const
	{
		ubyte[8] buf;
		import std.utf;
		auto status = U_ZERO_ERROR;
		ubyte[U_CNV_SAFECLONE_BUFFERSIZE] stackBuffer;
		int stackBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
		auto cnv = ucnv_safeClone(_converter, stackBuffer.ptr, &stackBufferSize, &status);
		icuEnforce(status);
		scope (exit)
			ucnv_close(cnv);
		wchar[2] pivotBuf;
		auto pivot = pivotBuf[0..std.utf.encode(pivotBuf, c)];
		ucnv_fromUChars(cnv, buf.ptr, cast(int)buf.length, pivot.ptr, cast(int)pivot.length, &status);
		return U_SUCCESS(status);
	}
	
	///
	override size_t encodedLength(dchar c) const
	{
		ubyte[8] buf;
		return encode(c, buf[]);
	}
	
	///
	override size_t encode(dchar c, ubyte[] buffer) const
	{
		import std.utf;
		auto status = U_ZERO_ERROR;
		ubyte[U_CNV_SAFECLONE_BUFFERSIZE] stackBuffer;
		int stackBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
		auto cnv = ucnv_safeClone(_converter, stackBuffer.ptr, &stackBufferSize, &status);
		icuEnforce(status);
		scope (exit)
			ucnv_close(cnv);
		wchar[2] pivotBuf;
		auto pivot = pivotBuf[0..std.utf.encode(pivotBuf, c)];
		auto len = ucnv_fromUChars(cnv, buffer.ptr, cast(int)buffer.length, pivot.ptr, cast(int)pivot.length, &status);
		icuEnforce(status);
		return len;
	}
	
	///
	override dchar decode(ref const(ubyte)[] s) const
	{
		import std.utf;
		auto status = U_ZERO_ERROR;
		ubyte[U_CNV_SAFECLONE_BUFFERSIZE] stackBuffer;
		int stackBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
		auto cnv = ucnv_safeClone(_converter, stackBuffer.ptr, &stackBufferSize, &status);
		icuEnforce(status);
		scope (exit)
			ucnv_close(cnv);
		auto srcstp = s.ptr;
		auto srcedp = s.ptr + s.length;
		auto ret = ucnv_getNextUChar(cnv, &srcstp, srcedp, &status);
		icuEnforce(status);
		s = s[srcstp - s.ptr .. s.length];
		return ret;
	}
	
	///
	override dchar safeDecode(ref const(ubyte)[] s) const
	{
		import std.utf;
		auto status = U_ZERO_ERROR;
		ubyte[U_CNV_SAFECLONE_BUFFERSIZE] stackBuffer;
		int stackBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
		auto cnv = ucnv_safeClone(_converter, stackBuffer.ptr, &stackBufferSize, &status);
		icuEnforce(status);
		scope (exit)
			ucnv_close(cnv);
		auto srcstp = s.ptr;
		auto srcedp = s.ptr + s.length;
		auto ret = ucnv_getNextUChar(cnv, &srcstp, srcedp, &status);
		if (U_FAILURE(status))
			return INVALID_SEQUENCE;
		s = s[srcstp - s.ptr .. s.length];
		return *cast(dchar*)&ret;
	}
	
	///
	override immutable(ubyte)[] replacementSequence() const @property
	{
		return [0xff, 0xfd];
	}
	
	
	///
	void decodeSequence(Range)(in ubyte[] src, Range dst)
	if (!isSomeString!Range && isOutputRange!(Range, dchar))
	{
		import std.conv;
		import std.algorithm;
		auto status = U_ZERO_ERROR;
		
		UChar[512] dstbuf;
		auto srcbufp = &src[0];
		auto endsrcp = srcbufp + src.length;
		auto dstbufp = &dstbuf[0];
		auto enddstp = dstbufp + dstbuf.length;
		
		static if (isOutputRange!(Range, char))
		{
			alias dststring = char[];
		}
		else static if (isOutputRange!(Range, wchar))
		{
			alias dststring = wchar[];
		}
		else static if (isOutputRange!(Range, dchar))
		{
			alias dststring = dchar[];
		}
		else static assert(0);
		
		while (srcbufp !is endsrcp)
		{
			auto dstp = dstbufp;
			ucnv_toUnicode(_converter, &dstp, enddstp, &srcbufp, endsrcp, null, true, &status);
			if (U_SUCCESS(status))
			{
				copy(dstbuf[0..(dstp - dstbufp)].to!dststring, dst);
				break;
			}
			import std.exception;
			enforce(status == U_BUFFER_OVERFLOW_ERROR);
			copy(dstbuf[0..(dstp - dstbufp)].to!dststring, dst);
			status = U_ZERO_ERROR;
		}
		ucnv_reset(_converter);
	}
	/// ditto
	void decodeSequence(Str)(in ubyte[] src, ref Str dst)
	if (isSomeString!Str)
	{
		auto app = appender!Str;
		decodeSequence(src, app);
		dst = app.data;
	}
	/// ditto
	string decodeSequence(in ubyte[] src)
	{
		string ret;
		decodeSequence(src, ret);
		return ret;
	}
	
	
	///
	void encodeSequence(Src, Range)(Src src, Range dst)
	if (isSomeString!Src && isOutputRange!(Range, ubyte))
	{
		import std.conv;
		import std.algorithm;
		auto status = U_ZERO_ERROR;
		
		ubyte[512] dstbuf;
		auto srcpivot = src.to!wstring();
		auto srcbufp = &srcpivot[0];
		auto endsrcp = srcbufp + srcpivot.length;
		auto dstbufp = &dstbuf[0];
		auto enddstp = dstbufp + dstbuf.length;
		
		while (srcbufp !is endsrcp)
		{
			auto dstp = dstbufp;
			ucnv_fromUnicode(_converter, &dstp, enddstp, &srcbufp, endsrcp, null, true, &status);
			if (U_SUCCESS(status))
			{
				copy(dstbuf[0..(dstp - dstbufp)], dst);
				break;
			}
			import std.exception;
			enforce(status == U_BUFFER_OVERFLOW_ERROR);
			//dst ~= dstbuf[0..(dstp - dstbufp)];
			copy(dstbuf[0..(dstp - dstbufp)], dst);
			status = U_ZERO_ERROR;
		}
		ucnv_reset(_converter);
	}
	/// ditto
	void encodeSequence(Str)(Str src, ref immutable(ubyte)[] dst)
	if (isSomeString!Str)
	{
		auto app = appender!(immutable(ubyte)[]);
		encodeSequence(src, app);
		dst = app.data;
	}
	/// ditto
	immutable(ubyte)[] encodeSequence(Str)(Str src)
	if (isSomeString!Str)
	{
		auto app = appender!(immutable(ubyte)[]);
		encodeSequence(src, app);
		return app.data;
	}
	
}

///
final class ICUEncodingSchemeImpl(string charsetName): ICUEncodingScheme
{
	shared static this()
	{
		EncodingScheme.register!(ICUEncodingSchemeImpl!charsetName);
	}
	///
	this()
	{
		super(charsetName);
	}
}

///
mixin template registerICUScheme(alias charsetName)
{
	shared static this()
	{
		alias scheme = ICUEncodingSchemeImpl!charsetName;
	}
}
