Module:       duim-extended-geometry-internals
Synopsis:     DUIM extended geometry
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Extended region protocol classes

define protocol-class polyline (<path>) end;

define protocol-class polygon (<area>) end;

define protocol-class line (<path>) end;

define protocol-class rectangle (<area>) end;

define protocol-class elliptical-arc (<path>) end;

define protocol-class ellipse (<area>) end;
