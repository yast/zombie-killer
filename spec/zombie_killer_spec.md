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
