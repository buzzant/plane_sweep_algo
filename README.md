# plane_sweep_algo
Plane-sweep algorithm for rectangles implemented with Julia

# Intersections
Finds intersections between rectangles using Plane-sweep algorithm

Rectangles are defined as Rect(index, l, r, b, t)
Where l is the left-most x coordinate etc..

The intersections are outputed as a list of (Rect1, Rect2, l, r, b, t) format

# HCG(Horizontal Constraint Graph)
HCG is represented as a nxn matrix
if rect2 is right of rect1, hcg[rect1, rect2] = 1 / else 0

such as
00100
00100
00010
00001
00000

[HCG_sample]