return function (x,y,z,w, m)
	return
	x * m[1] + y * m[5] + z * m[9]  + w * m[13],
	x * m[2] + y * m[6] + z * m[10] + w * m[14],
	x * m[3] + y * m[7] + z * m[11] + w * m[15],
	x * m[4] + y * m[8] + z * m[12] + w * m[16]
end
