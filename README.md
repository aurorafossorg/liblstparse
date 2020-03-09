# LST Parser for D Programming Language

This library provides a simple parser for LST coverage files.

## Usage

```d
LSTFile file = LSTFile("tests/res/foobar.lst");
writeln(file.filename); // foobar.d
writeln(file.totalCoverage) // 15

writeln(file.linesCovered[6]) // 0
// or even
writeln(file[6]) // 0
```

## How to contribute
Check out our [wiki](https://wiki.aurorafoss.org/).

## License
GNU Lesser General Public License (Version 3, 29 June 2007)

---
Made with ❤ by a bunch of geeks

[![License](https://img.shields.io/badge/license-LGPLv3-lightgrey.svg)](https://www.gnu.org/licenses/lgpl-3.0.html) [![Discord Server](https://discordapp.com/api/guilds/350229534832066572/embed.png)](https://discord.gg/4YuxJj)
