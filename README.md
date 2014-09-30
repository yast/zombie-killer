Zombie Killer
=============

In [YaST][y] we have tons of Ruby code which is ugly, because it was
[translated from a legacy language][yk], striving for bug-compatibility.

Zombie Killer analyzes the code for situations where it is safe
to replace the ugly variants with nice ones.

See the [runnable specification][spec] for details.

[y]:    https://github.com/yast
[yk]:   http://mvidner.blogspot.cz/2013/08/yast-in-ruby.html
[spec]: spec/zombie_killer_spec.md
