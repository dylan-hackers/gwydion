Module:       duim-geometry-internals
Synopsis:     DUIM geometry
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Basic protocol classes


/// Regions

define protocol-class region (<object>) end;

define protocol-class region-set (<region>) end;


/// Points, paths, and areas

define protocol-class point (<region>) end;

define protocol-class path (<region>) end;

define protocol-class area (<region>) end;


/// Transforms

define protocol-class transform (<object>) end;


/// Bounding boxes

// Note well that bounding boxes are not the same thing as rectangles!
define protocol-class bounding-box (<region>) end;
