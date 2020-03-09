module liblstparse.tests.parser;

import std.array;
import std.file;
import std.exception;
import core.exception;

import liblstparse.parser;
import aurorafw.unit.assertion;

@safe
@("No coverage")
unittest {
	LSTFile file = LSTFile("tests/res/nocov.lst");
	assertEquals("nocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertTrue(file.linesCovered.empty);
}


@safe
@("Zero coverage")
unittest {
	LSTFile file = LSTFile("tests/res/zerocov.lst");
	assertEquals("zerocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(0, file.linesCovered[6]);
}

@system
@("Range violation")
unittest {
	LSTFile file = LSTFile("tests/res/zerocov.lst");
	assertNotThrown!RangeError(file.linesCovered[6]);
	assertThrown!RangeError(file.linesCovered[4]);
}

@safe
@("File doesn't exist")
unittest {
	assertThrown!FileException(LSTFile("tests/res/file_not_found.lst"));
}

@safe
@("File with coverage")
unittest {
	LSTFile file = LSTFile(DirEntry("tests/res/tocov.lst"));
	assertEquals("tocov.d", file.filename);
	assertEquals(100, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(1, file.linesCovered[6]);
	assertEquals(file.linesCovered[6], file[6]);
	assertEquals(1, file.linesCovered[11]);
	assertEquals(file.linesCovered[11], file[11]);
}
