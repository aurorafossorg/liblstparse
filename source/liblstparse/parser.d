/*
                                    __
                                   / _|
  __ _ _   _ _ __ ___  _ __ __ _  | |_ ___  ___ ___
 / _` | | | | '__/ _ \| '__/ _` | |  _/ _ \/ __/ __|
| (_| | |_| | | | (_) | | | (_| | | || (_) \__ \__ \
 \__,_|\__,_|_|  \___/|_|  \__,_| |_| \___/|___/___/

Copyright (C) 2018-2020 Aurora Free Open Source Software.
Copyright (C) 2018-2020 Luís Ferreira <luis@aurorafoss.org>

This file is part of the Aurora Free Open Source Software. This
organization promote free and open source software that you can
redistribute and/or modify under the terms of the GNU Lesser General
Public License Version 3 as published by the Free Software Foundation or
(at your option) any later version approved by the Aurora Free Open Source
Software Organization. The license is available in the package root path
as 'LICENSE' file. Please review the following information to ensure the
GNU Lesser General Public License version 3 requirements will be met:
https://www.gnu.org/licenses/lgpl.html .

Alternatively, this file may be used under the terms of the GNU General
Public License version 3 or later as published by the Free Software
Foundation. Please review the following information to ensure the GNU
General Public License requirements will be met:
http://www.gnu.org/licenses/gpl-3.0.html.

NOTE: All products, services or anything associated to trademarks and
service marks used or referenced on this file are the property of their
respective companies/owners or its subsidiaries. Other names and brands
may be claimed as the property of others.

For more info about intellectual property visit: aurorafoss.org or
directly send an email to: contact (at) aurorafoss.org .
*/

/++
LST Parser

This file defines the LST format Parser

Authors: Luís Ferreira <luis@aurorafoss.org>
Copyright: All rights reserved, Aurora Free Open Source Software
License: GNU Lesser General Public License (Version 3, 29 June 2007)
Date: 2020
+/
module liblstparse.parser;

import std.algorithm;
import std.array;
import std.ascii;
import std.conv : to;
import std.exception;
import std.file;
import std.format;
import std.range.primitives;
import std.string;
import std.typecons;
import std.typecons;

///
class LSTFileParseException : Exception
{
	///
	mixin basicExceptionCtors;
}

///
class LSTFileMergeException : Exception
{
	///
	mixin basicExceptionCtors;
}

/** LST File struct
 *
 * This defines an LST File model with all associated covered lines.
 */
@safe public struct LSTFile
{
	/** LSTFile file content constructor
	 *
	 * This constructs a LSTFile using directly the content of the lst file
	 *
	 * Examples:
	 * --------------------
	 * auto text = readText("tuna.lst");
	 * LSTFile lst = LSTFile(text);
	 * --------------------
	 *
	 * Params:
	 *   text = content of the lst file
	 */
	@safe public this(string text)
	{
		import std.conv : to;

		auto buf = text.splitLines;

		if (buf.empty) // at the time, an empty file is generated from any empty .d file
			return;

		enforce!LSTFileParseException(buf.length >= 2,
				"Minimum number of lines is 2. Probably not parsing .lst file");

		foreach (i, ref line; buf[0 .. $ - 1])
		{
			immutable auto splittedLine = line.split("|");
			// check if the line is from a LST file
			enforce!LSTFileParseException(splittedLine.length >= 2,
					"'|' separator not found. Probably not parsing .lst file");

			immutable auto covered = splittedLine.front.strip;

			_lines ~= Line(
					(covered.empty) ? Nullable!(uint).init : nullable!uint(covered.to!uint),
					splittedLine[1 .. $].join);
		}

		auto finalLine = buf.back;

		if (!finalLine.endsWith(" has no code"))
		{
			auto s = finalLine.split("% covered");
			// check if it actually splits
			enforce!LSTFileParseException(s.length >= 2,
					"The last line is not well formatted: missing '% covered'");

			auto splitted = s.front.split(" ");
			_totalCoverage = splitted.back.to!ubyte;

			// check if lst is well formatted (has 'is' in splitted)
			enforce!LSTFileParseException(splitted[$ - 2] == "is",
					"The last line is not well formatted: missing ' is '");
			// remove ' is ' from 'filename.d is x% covered'
			_filename = splitted[0 .. $ - 2].join(" ");
		}
		else
		{
			_filename = finalLine.split(" has no code").front;
		}
	}

	/**
	 * LSTFile constructor
	 *
	 * This constructs the LSTFile from customizable parameters
	 *
	 * Params:
	 *   filename = file name of the covered .d file
	 *   lines = list of Line representing the coverage and line content
	 *   totalCoverage = total reported coverage in percentage
	 */
	@safe public this(string filename, Line[] lines, Nullable!ubyte totalCoverage = Nullable!(ubyte).init)
	{
		_filename = filename;
		_lines = lines;
		_totalCoverage = totalCoverage;
	}

	/** LSTFile direntry constructor
	 *
	 * This constructs a LSTFile using a DirEntry as a file
	 *
	 * Examples:
	 * --------------------
	 * LSTFile lst = LSTFile(DirEntry("tuna.lst"));
	 * --------------------
	 *
	 * Params:
	 *   file = file path
	 */
	@trusted public this(DirEntry file)
	in (file.isFile, "You should pass a file, not a directory!")
	{
		this(readText(file.name));
	}

	/**
	 * Constructs an LSTFile object from a given
	 * file path
	 *
	 * Params:
	 *   filepath = file path of the lst file
	 * Returns: constructed LSTFile object
	 */
	public static LSTFile fromFilePath(string filepath)
	{
		return LSTFile(DirEntry(filepath));
	}

	/**
	 * Generate the corresponding lst text file to this object
	 *
	 * Returns: generated lst file content
	 */
	public string generateLST()
	{
		auto ret = appender!string();
		if (_lines.empty) // at the time this is the behavior when generating lst file
			// from an empty .d file
			return "";

		// no need to calculate totalCoverage if there's no coverable lines and
		// _totalCoverage is null
		bool nocov = true;

		foreach (l; _lines)
		{
			auto genline = format!"|%s\n"(l.content);
			string prefixCov;
			if (l.coverage.isNull)
			{
				prefixCov = format!"%7s"(" "); // fill with spaces
			}
			else
			{
				nocov = false;
				if (l.coverage.get() == 0)
					prefixCov = format!"%07d"(0); // fill with 0s
				else
					prefixCov = format!"%7d"(l.coverage.get());
			}

			ret ~= prefixCov ~ genline;
		}

		if (nocov)
			ret ~= format!"%s has no code"(_filename);
		else
			ret ~= format!"%s is %d%% covered"(_filename, totalCoverage);

		return ret[];
	}

	/**
	 * Merge this LSTFile object with a given one
	 *
	 * Params:
	 *   lstfile = lstfile object to merge with
	 * Returns: merged lstfile object
	 */
	public LSTFile merge(LSTFile lstfile) const
	in
	{
		// check if the coverage report is from the exact same
		// source, otherwise fail
		enforce!LSTFileMergeException(lstfile._filename == _filename,
				"should merge with the same file");
		enforce!LSTFileMergeException(lstfile._lines.length == _lines.length,
				"lines length mismatch");

	}
	do
	{
		T getOr(T)(Nullable!T nullable, T t) const
		{
			if (!nullable.isNull)
				return nullable.get();
			return t;
		}

		// Can't use an appender here due to deprecation warning issue
		// See: https://issues.dlang.org/show_bug.cgi?id=20552
		Line[] lines;
		//auto lines = appender!(Line[]);

		foreach (idx, l; _lines)
		{
			enforce!LSTFileMergeException(l.content == lstfile._lines[idx].content,
					format!"content mismatch at line %s"(idx + 1));
			Nullable!uint cov;

			if (!(l.coverage.isNull && lstfile._lines[idx].coverage.isNull))
				cov = getOr(lstfile._lines[idx].coverage, 0) + getOr(l.coverage, 0);

			lines ~= Line(cov, l.content);
		}

		return LSTFile(lstfile._filename, lines[]);
	}

	/**
	 * Merge two given LSTFile objects
	 *
	 * Params:
	 *   lfile1 = first LSTFile object to merge
	 *   lfile2 = second LSTFile object to merge
	 * Returns: a merged LSTFIle object
	 */
	public static LSTFile merge(LSTFile lfile1, LSTFile lfile2)
	{
		return lfile1.merge(lfile2);
	}

	/**
	 * Returns: Path of the covered filename
	 */
	@safe pure public string filename() const @property
	{
		return _filename;
	}

	/**
	 * Returns: Total coverage percentage
	 */
	@safe pure public ubyte totalCoverage()
	{
		if (_totalCoverage.isNull)
		{
			auto assocArr = linesCovered();
			if (assocArr.empty)
			{
				_totalCoverage = nullable!ubyte(0);
				return 0;
			}

			size_t ret;
			foreach (k, v; assocArr)
				if (v > 0)
					ret++;

			// its fine to do this operation as it won't devide by 0 and its
			// also fine to cast this because it won't be greater than 100,
			// mathematically
			return (_totalCoverage = nullable!ubyte(
					cast(ubyte)((ret / cast(float) assocArr.length) * 100)
			)).get();

		}
		return _totalCoverage.get();
	}

	/**
	 * Returns: Associative array of coverable lines
	 */
	@safe pure public const(uint[size_t]) linesCovered() const @property
	{
		uint[size_t] ret;
		foreach (i, l; _lines)
			if (l.coverage.isNull)
				continue;
			else
				ret[i] = l.coverage.get();

		return ret;
	}

	/**
	 * Returns: Array of covered lines
	 */
	@safe pure public const(Line[]) lines() const @property
	{
		return _lines.dup;
	}

	/**
	 * Returns: Coverage value of the covered line
	 */
	@safe pure public Line opIndex(size_t i)
	{
		return _lines[i];
	}

	/**
	 * Coverable Line
	 *
	 * This struct defines a coverable line in the lst file.
	 */
	struct Line
	{
		/// coverage of that line (if appliable)
		Nullable!uint coverage;

		/// content of the line
		string content;
	}

	private string _filename;
	private Line[] _lines;
	private Nullable!ubyte _totalCoverage;
}
