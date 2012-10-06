void main() {
	int a, b, c, d, e;
	
	a = 0;
	b = 1;
	c = 2;
	d = 3;
	e = 4;
	
	a = -a;
	
	a = b + c;
	b = c - d;
	c = d * e;
	d = e / a;
	e = a % b;
	
	a += b;
	b -= c;
	c *= d;
	d /= e;
	e %= a;
	
	a = (b == c);
	b = (c != d);
	
	a = (b < c);
	b = (c > d);
	c = (d <= e);
	d = (e >= a);
}
