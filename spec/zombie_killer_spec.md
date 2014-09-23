Zombie Killer Specification
===========================

This document describes how [Zombie
Killer](https://github.com/yast/zombie-killer) kills various YCP zombies. It
serves both as a human-readable documentation and as an executable
specification. Technically, this is implemented by translating this document
from [Markdown](http://daringfireball.net/projects/markdown/) into
[RSpec](http://rspec.info/).

Literals
--------

Zombie Killer translates `Ops.add` of two string literals.

**Original**

```ruby
Ops.add("Hello", "World")
```

**Translated**

```ruby
"Hello" + "World"
```

Zombie Killer translates assignment of `Ops.add` of two string literals.

**Original**

```ruby
v = Ops.add("Hello", "World")
```

**Translated**

```ruby
v = "Hello" + "World"
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

Zombie Killer does not translate Ops.add if any argument is ugly.

**Original**

```ruby
Ops.add("Hello", world)
```

**Translated**

```ruby
Ops.add("Hello", world)
```

Literal Variables
-----------------

### One argument is a variable set to a literal

Zombie Killer translates `Ops.add(variable, literal)`.

**Original**

```ruby
v = "Hello"; Ops.add(v, "World")
```

**Translated**

```ruby
v = "Hello"; v + "World"
```

Zombie Killer translates `Ops.add(literal, variable)`.

**Original**

```ruby
v = "World"; Ops.add("Hello", v)
```

**Translated**

```ruby
v = "World"; "Hello" + v
```

### Argument is variable set to a literal, passed via another var

Zombie Killer translates `Ops.add(variable, literal)`.

**Original**

```ruby
v = "Hello"; v2 = v; Ops.add(v2, "World")
```

**Translated**

```ruby
v = "Hello"; v2 = v; v2 + "World"
```

### One argument is a variable set to a literal but mutated

Zombie Killer does not translate `Ops.add(variable, literal)`.

**Original**

```ruby
v = "Hello"; v = f(v); Ops.add(v, "World")
```

**Translated**

```ruby
v = "Hello"; v = f(v); Ops.add(v, "World")
```

### Multiple `def`s

Zombie Killer does not confuse variables across `def`s.

**Original**

```ruby
def a
  v = "literal"
end

def b(v)
  Ops.add(v, "literal")
end
```

**Translated**

```ruby
def a
  v = "literal"
end

def b(v)
  Ops.add(v, "literal")
end
```

Localized Literals
------------------

### Argument is a variable set to a localized literal

Zombie Killer translates `Ops.add(variable, literal)`.

**Original**

```ruby
v = _("Hello"); Ops.add(v, "World")
```

**Translated**

```ruby
v = _("Hello"); v + "World"
```

Zombie Killer translates `Ops.add(variable, localized literal)`.

**Original**

```ruby
v = _("Hello"); Ops.add(v, _("World"))
```

**Translated**

```ruby
v = _("Hello"); v + _("World")
```

Add Chains
----------

### Since we have implemented iterated translation

Zombie Killer translates a chain of `Ops.add` of literals.

**Original**

```ruby
Ops.add(Ops.add("Hello", " "), "World")
```

**Translated**

```ruby
("Hello" + " ") + "World"
```
Zombie Killer translates a right-assoc chain of `Ops.add` of literals.

**Original**

```ruby
Ops.add("Hello", Ops.add(" ", "World"))
```

**Translated**

```ruby
"Hello" + (" " + "World")
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

**Original**

```ruby
Ops.add(
  "Hello",
  # foo
  "World"
)
```

**Translated**

```ruby
Ops.add(
  "Hello",
  # foo
  "World"
)
```
