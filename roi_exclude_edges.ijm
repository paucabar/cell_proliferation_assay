n=nResults;
getDimensions(width, height, channels, slices, frames);
toScaled(width);
toScaled(height);
for (i=0; i<n; i++) {
	bx=getResult("BX", i);
	by=getResult("BY", i);
	iWidth=getResult("Width", i);
	iHeight=getResult("Height", i);	
	if (bx == 0 || by == 0 || bx + iWidth >= width || by + iHeight >= height) {
		label=getResultLabel(i);
		label=substring(label, indexOf(label, ":") + 1);
		print(label);
	}
}
