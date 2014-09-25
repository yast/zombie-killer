Zombie Killer Specification
===========================

This document describes how [Zombie
Killer](https://github.com/yast/zombie-killer) kills various YCP zombies. It
serves both as a human-readable documentation and as an executable
specification. Technically, this is implemented by translating this document
from [Markdown](http://daringfireball.net/projects/markdown/) into
[RSpec](http://rspec.info/).

Table Of Contents
-----------------

1. Concepts
1. Literals
1. Variables
1. Calls Preserving Niceness
    1. Calls Generating Niceness
1. Translation Below Top Level
1. Chained Translation
1. Formatting
1. Too Complex Code

Concepts
--------

A **zombie** is a Ruby method call emulating a quirk of the YCP language that
YaST was formerly implemented in.  `Ops.add` will serve as an example of a
simple zombie. The library implementation simply returns `nil` if any argument
is `nil`. Compare this to `+` which raises an exception if it gets
`nil`. Therefore `Ops.add` can be translated to the `+` operator, as long as
its arguments are not `nil`.

A **nice** value is one that cannot be `nil` and is therefore suitable as an
argument to a native operator.

An **ugly** value is one that may be `nil`.

Literals
--------

String and integer literals are obviously nice. `nil` is a literal too but it
is ugly.

Zombie Killer translates `Ops.add` of two string literals.

**Original**

```ruby
Ops.add("Hello", "World")
```

**Translated**

```ruby
"Hello" + "World"
```

Zombie Killer translates `Ops.add` of two integer literals.

**Original**

```ruby
Ops.add(40, 2)
```

**Translated**

```ruby
40 + 2
```

Zombie Killer translates assignment of `Ops.add` of two string literals.
(Move this to "translate deeper than at top level")

**Original**

```ruby
v = Ops.add("Hello", "World")
```

**Translated**

```ruby
v = "Hello" + "World"
```

Zombie Killer does not translate Ops.add if any argument is ugly.

**Unchanged**

```ruby
Ops.add("Hello", world)
```

Zombie Killer does not translate Ops.add if any argument is the nil literal.

**Unchanged**

```ruby
Ops.add("Hello", nil)
```

Variables
---------

If a local variable is assigned a nice value, we remember that.

Zombie Killer translates `Ops.add(nice_variable, literal)`.

**Original**

```ruby
v = "Hello"
Ops.add(v, "World")
```

**Translated**

```ruby
v = "Hello"
v + "World"
```

Zombie Killer translates `Ops.add(nontrivially_nice_variable, literal)`.

**Original**

```ruby
v  = "Hello"
v2 = v
v  = uglify
Ops.add(v2, "World")
```

**Translated**

```ruby
v  = "Hello"
v2 = v
v  = uglify
v2 + "World"
```

We have to take care to revoke a variable's niceness if appropriate.

Zombie Killer does not translate `Ops.add(mutated_variable, literal)`.

**Unchanged**

```ruby
v = "Hello"
v = f(v)
Ops.add(v, "World")
```

Zombie Killer does not confuse variables across `def`s.

**Unchanged**

```ruby
def a
  v = "literal"
end

def b(v)
  Ops.add(v, "literal")
end
```

Calls Preserving Niceness
-------------------------

A localized string literal is nice.

**Original**

```ruby
v = _("Hello")
Ops.add(v, "World")
```

**Translated**

```ruby
v = _("Hello")
v + "World"
```

### Calls Generating Niceness ###

`nil?` makes any value a nice value but unfortunately it seems of
little practical use. Even though there are two zombies that have
boolean arguments (`Builtins.find` and `Builtins.filter`), they are
just fine with `nil` since it is a falsey value.

Translation Below Top Level
---------------------------

Zombie Killer translates a zombie nested in other calls.

**Original**

```ruby
v = 1
foo(bar(Ops.add(v, 1), baz))
```

**Translated**

```ruby
v = 1
foo(bar(v + 1, baz))
```

Chained Translation
-------------------

Zombie Killer translates a left-associative  chain of nice zombies.

**Original**

```ruby
Ops.add(Ops.add(1, 2), 3)
```

**Translated**

```ruby
(1 + 2) + 3
```

Zombie Killer translates a right-associative chain of nice zombies.

**Original**

```ruby
Ops.add(1, Ops.add(2, 3))
```

**Translated**

```ruby
1 + (2 + 3)
```

### In case arguments are translated already

Zombie Killer translates `Ops.add` of plus and literal.

**Original**

```ruby
Ops.add("Hello" + " ", "World")
```

**Translated**

```ruby
("Hello" + " ") + "World"
```

Zombie Killer translates `Ops.add` of parenthesized plus and literal.

**Original**

```ruby
Ops.add(("Hello" + " "), "World")
```

**Translated**

```ruby
("Hello" + " ") + "World"
```

Zombie Killer translates `Ops.add` of literal and plus.

**Original**

```ruby
Ops.add("Hello", " " + "World")
```

**Translated**

```ruby
"Hello" + (" " + "World")
```

Formatting
----------

Zombie Killer does not translate `Ops.add` if any argument has a comment.

**Unchanged**

```ruby
Ops.add(
  "Hello",
  # foo
  "World"
)
```

Too Complex Code
----------------

Too Complex Code is one that contains `rescue`, `ensure`,
`block`, `while`, while-post...
FIXME actually we should whitelist the nodes we know to be safe!

Translating that properly requires data flow analysis which we do not do yet.

Zombie Killer does not translate anything in a `def` that contains
Too Complex Code.

**Unchanged**

```ruby
def d
  v = "A"
  while cond
    w = Ops.add(v, "A")
    v = uglify
  end
end
```

Zombie killer does not translate anything in the outer scope that contains
Too Complex Code.

**Unchanged**

```ruby
v = "A"
while cond
  w = Ops.add(v, "A")
  v = uglify
end
```
