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

Installation
------------

Source: clone the git repository.

Dependencies: run `bundle`.
(On openSUSE, most dependencies are packaged as rubygem-*.rpm except `unparser`)

Usage
-----

`zk [FILES...]` works in place, so it is best to use in a Git checkout.
By default it finds all `*.rb` files under the current directory.
