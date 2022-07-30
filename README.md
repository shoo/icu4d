# ICU(International Components for Unicode) for D
[![status](https://github.com/shoo/icu4d/workflows/status/badge.svg)](https://github.com/shoo/icu4d/actions?query=workflow%3Astatus)
[![master](https://github.com/shoo/icu4d/workflows/master/badge.svg)](https://github.com/shoo/icu4d/actions?query=workflow%3Amaster)
[![dub](https://img.shields.io/dub/v/icu4d.svg?cacheSeconds=3600)](https://code.dlang.org/packages/icu4d)
[![downloads](https://img.shields.io/dub/dt/icu4d.svg?cacheSeconds=3600)](https://code.dlang.org/packages/icu4d)
[![BSL-1.0](http://img.shields.io/badge/license-BSL--1.0-blue.svg?style=flat)](./LICENSE)
[![codecov](https://codecov.io/gh/shoo/icu4d/branch/master/graph/badge.svg)](https://codecov.io/gh/shoo/icu4d)
[![ICU-Version](http://img.shields.io/badge/icu%20version-70.1-green.svg?style=flat)](https://github.com/unicode-org/icu/releases/tag/release-70-1)

This project provides EncodingScheme of std.encoding based on ICU(International Components for Unicode).

# Usage

If you are using dub, you can add a dependency by describing it as follows:

```json
"dependencies": {
    "icu4d": "~>70.1",
}
```

On Windows, the package includes binaries, so you can use it as is.  
On Linux or MacOS, the ICU must be installed. Be sure to specify the version of the ICU.

```sh
apt install libicu-dev=70.1-2
```

If the required version is not provided by the package manager, you will need to build it from source code.

```sh
apt install -y git build-essential libicu-le-hb0 libicu-le-hb-dev
git clone -b release-70-1 --depth 1 --single-branch https://github.com/unicode-org/icu.git
cd icu/icu4c/source
./runConfigureICU Linux --disable-samples --disable-tests --with-data-packaging=library
make -j2
make install
```

## Dynamic link ICU4C
For dynamic linking, use subconfigurations in addition to dependencies.

```json
"dependencies": {
    "icu4d": "~>70.1",
}
"subConfigurations": {
    "icu4d": "dynamic"
}
```

`icu4d` automatically initialize the dependent library bindbc.icu when register EncodingScheme.
Then, register the EncodingScheme to std.encoding:

```d
import icu4d;
mixin registerICUScheme!"Shift_JIS";

void main()
{
    auto textpart = "ごん、お前だったのか。いつも栗をくれたのは";
    auto sjistext  = textpart.encodeText!"Shift_JIS"();
    auto utf16text = textpart.encodeText!"UTF-16LE"();
    assert(sjistext.decodeText!"Shift_JIS"() == utf16text.decodeText!"UTF-16LE"());
}
```

## Static link ICU4C(default)
For static linking, use subconfigurations in addition to dependencies.

```json
"dependencies": {
    "icu4d": "~>70.1",
}
"subConfigurations": {
    "icu4d": "static"
}
```

Then, register the EncodingScheme to std.encoding:

```d
import icu4d;
mixin registerICUScheme!"EUC-JP";

void main()
{
    auto textpart = "青い煙が、まだ筒口から細く出ていました。";
    auto eucjptext = textpart.encodeText!"EUC-JP"();
    auto utf16text = textpart.encodeText!"UTF-16LE"();
    assert(eucjptext.decodeText!"EUC-JP"() == utf16text.decodeText!"UTF-16LE"());
}
```

# Contributing
This project accepts [Issue](https://github.com/shoo/icu4d/issues) reports and [PullRequests](https://github.com/shoo/icu4d/pulls).
The PullRequest must pass all tests in CI of [GitHub Actions](https://github.com/shoo/icu4d/actions).
First, make sure that your environment passes the test with the following commands.

```sh
rdmd scripts/runner.d -m=ut # or dub test
rdmd scripts/runner.d -m=it # or dub build / test / run for all ./testcases/* directories.
```

# License

This library(icu4d) is provided by provided under the [BSL-1.0](./LICENSE), but the ICU(ICU4C) on which this library depends is provided under the [ICU License](https://github.com/unicode-org/icu/blob/master/icu4c/LICENSE).
