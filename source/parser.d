/*
                                    __
                                   / _|
  __ _ _   _ _ __ ___  _ __ __ _  | |_ ___  ___ ___
 / _` | | | | '__/ _ \| '__/ _` | |  _/ _ \/ __/ __|
| (_| | |_| | | | (_) | | | (_| | | || (_) \__ \__ \
 \__,_|\__,_|_|  \___/|_|  \__,_| |_| \___/|___/___/

Copyright (C) 2018-2020 Aurora Free Open Source Software.

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

import std.file;
import std.string;
import std.range.primitives;
import std.algorithm.searching;
import std.typecons;
import std.algorithm.iteration;
import std.array;


/** LST File struct
 *
 * This defines an LST File model with all associated covered lines.
 */
@safe
public struct LSTFile
{
	/** LSTFile filename constructor
	 *
	 * This constructs a LSTFile using directly the path of filename string
	 *
	 * Examples:
	 * --------------------
	 * LSTFile lst = LSTFile("tuna.lst");
	 * --------------------
	 */
	@safe
	public this(string filename)
	{
		import std.conv : to;

		auto buf = readText(filename)
			.splitLines;

		foreach(i, ref line; buf[0 .. $-1])
		{
			immutable auto covered = line.split("|").front.strip;

			if(covered.empty)
				continue;

			this._linesCovered[i+1] = covered.to!int;
		}

		auto finalLine = buf.back;

		if(!finalLine.endsWith(" has no code"))
		{
			auto splitted = finalLine.split("% covered").front.split(" ");
			this._totalCoverage = splitted.back.to!byte;
			this._filename = splitted[0 .. $ - 2].join(" ");
		}
		else
		{
			this._filename = finalLine.split(" has no code").front;	
		}
	}


	/** LSTFile direntry constructor
	 *
	 * This constructs a LSTFile using a DirEntry as a file
	 *
	 * Examples:
	 * --------------------
	 * LSTFile lst = LSTFile("tuna.lst");
	 * --------------------
	 */
	@safe
	public this(DirEntry file)
	{
		assert(file.isFile, "You should pass a file, not a directory!");
		this(file.name);
	}


	/**
	 * Returns: Path of the covered filename
	 */
	@safe pure
	public string filename() const @property
	{
		return _filename;
	}


	/**
	 * Returns: Total coverage percentage
	 */
	@safe pure
	public ubyte totalCoverage() const @property
	{
		return _totalCoverage;
	}


	/**
	 * Returns: Associative array of covered lines
	 */
	@safe pure
	public const(int[size_t]) linesCovered() const @property
	{
		return _linesCovered.dup;
	}

	/**
	 * Returns: Coverage value of the covered line
	 */
	@safe pure
	public int opIndex(size_t i)
	{
		return _linesCovered[i];
	}


	private string _filename;
	private ubyte _totalCoverage;
	private int[size_t] _linesCovered;
}
