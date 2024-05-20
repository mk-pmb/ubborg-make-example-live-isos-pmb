#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

/^TASK /{
  N
  s! +! !g
  s~\] \*+\n[A-Z][a-z]{2,8}day [0-9]{1,2} [A-Z][a-z]{2,12} [0-9]{4} ($\
    |[0-9]{2}:[0-9]{2}:[0-9]{2}) [+-][0-9]{4} \(([0-9:\.]+)\) ([0-9:\.]+|$\
    ) (\*+)\s*$~\r<timings>\n\1 \f\2 \f\3~
  /\r<timings>/{
    s~\[~~
    s~\f(0+:)+~\f~g
    s~\f0([0-9]\.)~\1~g
    s~\f~~g
    s~^TASK ([^\r]*)\r<timings>\n(\S+) (\S+) (\S+)$~TASK  \2  +\3  =\4  \1~
  }
}

/^PLAY /d
/^(ok|changed): \[/d
/^$/d
