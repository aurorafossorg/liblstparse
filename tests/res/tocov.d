module tests.res.tocov;

///
int foo(int t) {
	return t * 2;
}

///
unittest {
	assert(foo(2) == 4);
}
