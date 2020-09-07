module liblstparse.tests.parser;

import aurorafw.unit.assertion;

import core.exception;

import liblstparse.parser;

import std.array;
import std.exception;
import std.file;
import std.typecons;

@safe @("No coverage")
unittest {
	LSTFile file = LSTFile(DirEntry("tests/res/nocov.lst"));
	assertEquals("nocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertEquals("@safe unittest {", file[3].content);
	assertTrue(file.linesCovered.empty);
	// check a non coverable file
	assertEquals(
		LSTFile.Line(Nullable!(uint).init, "module tests.res.nocov;"),
		file.lines[0]);
}

@safe @("Zero coverage")
unittest {
	LSTFile file = LSTFile(DirEntry("tests/res/zerocov.lst"));
	assertEquals("zerocov.d", file.filename);
	assertEquals(0, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(0, file.linesCovered[4]);
}

@safe @("Convertion failures")
unittest {
	auto overflow_file = `
       |@safe int foo(int t) {
81723948712938471923874918273498273941872394|        return t * 2;
       |}
covfile.d is 100% covered`[1 .. $];
	auto overflow2_file = `
       |@safe int foo(int t) {
      1|        return t * 2;
       |}
covfile.d is 819723498712398471293% covered`[1 .. $];
	auto failconv_file = `
       |@safe int foo(int t) {
notaninteger|        return t * 2;
       |}
covfile.d is 100% covered`[1 .. $];
	auto failconv2_file = `
       |@safe int foo(int t) {
      1|        return t * 2;
       |}
covfile.d is ups% covered`[1 .. $];

	import std.conv : ConvException, ConvOverflowException;
	expectThrows!ConvOverflowException(LSTFile(overflow_file));
	expectThrows!ConvOverflowException(LSTFile(overflow2_file));
	expectThrows!ConvException(LSTFile(failconv_file));
	expectThrows!ConvException(LSTFile(failconv2_file));
}

@safe @("Parsing failures")
unittest {
	// minimum valid lst files
	LSTFile("|\na.d has no code");
	LSTFile("1|int main(){return 0;}\nb.d is 100% covered");

	LSTFileParseException ex;

	// invalid files
	ex = expectThrows!LSTFileParseException(LSTFile("hey, I like turtles"));
	assertEquals("Minimum number of lines is 2. Probably not parsing .lst file", ex.msg);
	ex = expectThrows!LSTFileParseException(LSTFile("hey, I like turtles\n."));
	assertEquals("'|' separator not found. Probably not parsing .lst file", ex.msg);
	ex = expectThrows!LSTFileParseException(LSTFile("|\n 100"));
	assertEquals("The last line is not well formatted: missing '% covered'", ex.msg);
	ex = expectThrows!LSTFileParseException(
		LSTFile("1|int main(){return 0;}\nb.d iss 100% covered"));
	assertEquals("The last line is not well formatted: missing ' is '", ex.msg);
}

@safe @("Merge coverage files")
unittest {
	// NOTE: This files doesn't represent real coverage
	// but should be totally valid LST files.
	auto covfile1 = `
       |@safe int foo(int t) {
      1|        return t * 2;
       |}
covfile.d is 100% covered`[1 .. $];
	auto covfile2 = `
       |@safe int foo(int t) {
      2|        return t * 2;
       |}
covfile.d is 0% covered`[1 .. $];
	auto covfile3 = `
       |@safe int foo(int t) {
       |        return t * 2;
       |}
covfile.d is 0% covered`[1 .. $];
	auto diffcovfile1 = `
       |@safe int foo(int t) {
      0|        return t * 2;
       |}
diffcovfile.d is 0% covered`[1 .. $];
	auto diffcovfile2 = `
       |@safe int foobar(int t) {
      0|        return t * 2;
       |}
diffcovfile.d is 0% covered`[1 .. $];
	auto diffcovfile3 = `
       |@safe int foobar(int t) {
      0|        return t * 2;
       |
       |}
diffcovfile.d is 0% covered`[1 .. $];

	LSTFile file1 = LSTFile(covfile1);
	LSTFile file2 = LSTFile(covfile2);
	LSTFile file3 = LSTFile(covfile3);
	LSTFile diff_file1 = LSTFile(diffcovfile1);
	LSTFile diff_file2 = LSTFile(diffcovfile2);
	LSTFile diff_file3 = LSTFile(diffcovfile3);

	// successfully merge a file
	LSTFile merged = file1.merge(file2);
	assertEquals("covfile.d", merged.filename);
	assertEquals(100, merged.totalCoverage);
	assertFalse(merged.linesCovered.empty);
	assertEquals(3, merged.linesCovered[1]);

	// merge coverable with non coverable lines
	merged = file2.merge(file3);
	assertEquals(2, merged.linesCovered[1]);

	// cover usage of divide by 0 check
	merged = file3.merge(file3);
	assertEquals(0, merged.totalCoverage);


	LSTFileMergeException ex;

	// different filename
	ex = expectThrows!LSTFileMergeException(LSTFile.merge(file1, diff_file1));
	assertEquals("should merge with the same file", ex.msg);
	// line length mismatch, not the same content
	ex = expectThrows!LSTFileMergeException(LSTFile.merge(diff_file1, diff_file3));
	assertEquals("lines length mismatch", ex.msg);
	// file content mismatch, not the same content
	ex = expectThrows!LSTFileMergeException(LSTFile.merge(diff_file1, diff_file2));
	assertEquals("content mismatch at line 1", ex.msg);
}

@system @("Range violation")
unittest {
	LSTFile file = LSTFile.fromFilePath("tests/res/zerocov.lst");
	assertNotThrown!RangeError(file.linesCovered[4]);
	assertThrown!RangeError(file.linesCovered[3]);
}

@safe @("File doesn't exist")
unittest {
	expectThrows!FileException(LSTFile(DirEntry("tests/res/file_not_found.lst")));
}

@safe @("File with coverage")
unittest {
	import std.file : readText;
	auto txt = readText("tests/res/tocov.lst");
	LSTFile file = LSTFile(txt);
	assertEquals("tocov.d", file.filename);
	assertEquals(100, file.totalCoverage);
	assertFalse(file.linesCovered.empty);
	assertEquals(1, file.linesCovered[4]);
	assertEquals(file.linesCovered[4], file[4].coverage);
	assertEquals(1, file.linesCovered[9]);
	assertEquals(file.linesCovered[9], file[9].coverage);

	// check a coverable file
	assertEquals(
		LSTFile.Line(nullable!uint(1), "        return t * 2;"),
		file.lines[4]
	);
}
