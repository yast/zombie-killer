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

`zk FILE...` works in place, so it is best to use in a git checkout.

For a practical demo, try

```bash
find -name \*.rb | xargs zk --unsafe
```

Issues
------

Notice the `--unsafe` (or `-u`) option. Without it, Zombie Killer works well,
on its test cases but fails on any real code. To run in the wild, be aware
that there are still cases where Zombie Killer incorrectly kills a zombie
where it is not correct, such as this one:

```ruby
def a_problem
  v = nil
  w = 1 / 0
  v = 1
rescue
  puts "Oops", Ops.add(v, 1)
end
```
