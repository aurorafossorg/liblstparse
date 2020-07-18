module liblstparse.tests.parser;

import aurorafw.unit.assertion;

import core.exception;

import liblstparse.parser;

import std.array;
import std.exception;
import std.file;

@safe @("No coverage")
unittest {
	LSTFile file = LSTFile("tests/res/nocov.lst");
	assertEquals("nocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertTrue(file.linesCovered.empty);
}

@safe @("Zero coverage")
unittest {
	LSTFile file = LSTFile("tests/res/zerocov.lst");
	assertEquals("zerocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(0, file.linesCovered[5]);
}

@system @("Range violation")
unittest {
	LSTFile file = LSTFile("tests/res/zerocov.lst");
	assertNotThrown!RangeError(file.linesCovered[5]);
	assertThrown!RangeError(file.linesCovered[4]);
}

@safe @("File doesn't exist")
unittest {
	assertThrown!FileException(LSTFile("tests/res/file_not_found.lst"));
}

@safe @("File with coverage")
unittest {
	LSTFile file = LSTFile(DirEntry("tests/res/tocov.lst"));
	assertEquals("tocov.d", file.filename);
	assertEquals(100, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(1, file.linesCovered[5]);
	assertEquals(file.linesCovered[5], file[5]);
	assertEquals(1, file.linesCovered[10]);
	assertEquals(file.linesCovered[10], file[10]);
}
