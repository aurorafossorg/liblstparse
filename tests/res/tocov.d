module tests.res.tocov;

///
@safe int foo(int t) {
	return t * 2;
}

///
@safe unittest {
	assert(foo(2) == 4);
}
