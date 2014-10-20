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
1. If
1. Case
1. Loops
    1. While and Until
1. Exceptions
1. Blocks
1. Formatting

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

Zombie Killer does not confuse variables across `def self.`s.

**Unchanged**

```ruby
v = 1

def self.foo(v)
  Ops.add(v, 1)
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

If
--

With a **single-pass top-down data flow analysis**, that we have been using,
we can process the `if` statement but not beyond it,
because we cannot know which branch was taken.

We can proceed after the `if` statement but must **start with a clean slate**.
More precisely we should remove knowledge of all variables affected in either
branch of the `if` statement, but we will first simplify the job and wipe all
state for the processed method.

Zombie Killer translates the `then` body of an `if` statement.

**Original**

```ruby
if cond
  Ops.add(1, 1)
end
```

**Translated**

```ruby
if cond
  1 + 1
end
```

Zombie Killer translates the `then` body of an `unless` statement.

**Original**

```ruby
unless cond
  Ops.add(1, 1)
end
```

**Translated**

```ruby
unless cond
  1 + 1
end
```

It translates both branches of an `if` statement, independently of each other.

**Original**

```ruby
v = 1
if cond
  Ops.add(v, 1)
  v = nil
else
  Ops.add(1, v)
  v = nil
end
```

**Translated**

```ruby
v = 1
if cond
  v + 1
  v = nil
else
  1 + v
  v = nil
end
```

The condition also contributes to the data state.

**Original**

```ruby
if cond(v = 1)
  Ops.add(v, 1)
end
```

**Translated**

```ruby
if cond(v = 1)
  v + 1
end
```

### A variable is not nice after its niceness was invalidated by an `if`

Plain `if`

**Unchanged**

```ruby
v = 1
if cond
  v = nil
end
Ops.add(v, 1)
```

Trailing `if`.

**Unchanged**

```ruby
v = 1
v = nil if cond
Ops.add(v, 1)
```

Plain `unless`.

**Unchanged**

```ruby
v = 1
unless cond
  v = nil
end
Ops.add(v, 1)
```

Trailing `unless`.

**Unchanged**

```ruby
v = 1
v = nil unless cond
Ops.add(v, 1)
```

### Resuming with a clean slate after an `if`

It translates zombies whose arguments were found nice after an `if`.

**Original**

```ruby
if cond
   v = nil
end
v = 1
Ops.add(v, 1)
```

**Translated**

```ruby
if cond
   v = nil
end
v = 1
v + 1
```

Case
----

With a **single-pass top-down data flow analysis**, that we have been using,
we can process the `case` statement but not beyond it,
because we cannot know which branch was taken.

We can proceed after the `case` statement but must **start with a clean slate**.
More precisely we should remove knowledge of all variables affected in either
branch of the `case` statement, but we will first simplify the job and wipe all
state for the processed method.

Zombie Killer translates the `when` body of a `case` statement.

**Original**

```ruby
case expr
  when 1
    Ops.add(1, 1)
end
```

**Translated**

```ruby
case expr
  when 1
    1 + 1
end
```

It translates all branches of a `case` statement, independently of each other.

**Original**

```ruby
v = 1
case expr
  when 1
    Ops.add(v, 1)
    v = nil
  when 2
    Ops.add(v, 2)
    v = nil
  else
    Ops.add(1, v)
    v = nil
end
```

**Translated**

```ruby
v = 1
case expr
  when 1
    v + 1
    v = nil
  when 2
    v + 2
    v = nil
  else
    1 + v
    v = nil
end
```

The expression also contributes to the data state.

**Original**

```ruby
case v = 1
  when 1
    Ops.add(v, 1)
end
```

**Translated**

```ruby
case v = 1
  when 1
    v + 1
end
```

The test also contributes to the data state.

**Original**

```ruby
case expr
  when v = 1
    Ops.add(v, 1)
end
```

**Translated**

```ruby
case expr
  when v = 1
    v + 1
end
```

### A variable is not nice after its niceness was invalidated by a `case`

**Unchanged**

```ruby
v = 1
case expr
  when 1
    v = nil
end
Ops.add(v, 1)
```

### Resuming with a clean slate after a `case`

It translates zombies whose arguments were found nice after a `case`.

**Original**

```ruby
case expr
  when 1
    v = nil
end
v = 1
Ops.add(v, 1)
```

**Translated**

```ruby
case expr
  when 1
    v = nil
end
v = 1
v + 1
```

Loops
-----

### While and Until

`while` and its negated twin `until` are loops
which means assignments later in its body can affect values
earlier in its body and in the condition. Therefore we cannot process either
one and we must clear the state afterwards.

Zombie Killer does not translate anything in the outer scope
that contains a `while`.

**Unchanged**

```ruby
v = 1
while Ops.add(v, 1)
  Ops.add(1, 1)
end
Ops.add(v, 1)
```

Zombie Killer does not translate anything in the outer scope
that contains an `until`.

**Unchanged**

```ruby
v = 1
until Ops.add(v, 1)
  Ops.add(1, 1)
end
Ops.add(v, 1)
```

Zombie Killer can continue processing after a `while`. Pun!

**Original**

```ruby
while cond
  foo
end
v = 1
Ops.add(v, 1)
```

**Translated**

```ruby
while cond
  foo
end
v = 1
v + 1
```

Zombie Killer can continue processing after an `until`. No pun.

**Original**

```ruby
until cond
  foo
end
v = 1
Ops.add(v, 1)
```

**Translated**

```ruby
until cond
  foo
end
v = 1
v + 1
```

Zombie Killer can parse both the syntactic and semantic post-condition.

**Unchanged**

```ruby
body_runs_after_condition while cond
body_runs_after_condition until cond

begin
  body_runs_before_condition
end while cond

begin
  body_runs_before_condition
end until cond
```

Exceptions
----------

Raising an exception is not a problem at the `raise` site. There it means
that all remaining code in a `def` is skipped. It is a problem at the `rescue`
or `ensure` site where it means that *some* of the preceding code was not
executed.

Zombie Killer translates the parts, joining else, rescue separately.

**Original**

```ruby
def foo
  v = 1
  Ops.add(v, 1)
rescue
  w = 1
  Ops.add(w, 1)
  v = nil
rescue
  Ops.add(w, 1)
else
  Ops.add(v, 1)
end
```

**Translated**

```ruby
def foo
  v = 1
  v + 1
rescue
  w = 1
  w + 1
  v = nil
rescue
  Ops.add(w, 1)
else
  v + 1
end
```

### Skipping Code

Zombie Killer does not translate code that depends on niceness skipped
via an exception.

**Unchanged**

```ruby
def a_problem
  v = nil
  w = 1 / 0
  v = 1
rescue
  puts "Oops", Ops.add(v, 1)
end
```

### Exception Syntax

Zombie Killer can parse the syntactic variants of exception handling.

**Unchanged**

```ruby
begin
  foo
  raise "LOL"
  foo
rescue Error
  foo
rescue Bug, Blunder => b
  foo
rescue => e
  foo
rescue
  foo
ensure
  foo
end
yast rescue nil
```

### Retry

The `retry` statement makes the begin-body effectively a loop which limits
our translation possibilities.

Zombie Killer does not translate a begin-body when a rescue contains a retry.

**Unchanged**

```ruby
def foo
  v = 1
  begin
    Ops.add(v, 1)
    maybe_raise
  rescue
    v = nil
    retry
  end
end
```

Blocks
------

Inside a block the data flow is more complex than we handle now.
After it, we start anew.

Zombie Killer does not translate inside a block and resumes with a clean slate.

**Original**

```ruby
v = 1
v = Ops.add(v, 1)

2.times do
  v = Ops.add(v, 1)
  v = uglify
end

v = Ops.add(v, 1)
w = 1
w = Ops.add(w, 1)
```

**Translated**

```ruby
v = 1
v = v + 1

2.times do
  v = Ops.add(v, 1)
  v = uglify
end

v = Ops.add(v, 1)
w = 1
w = w + 1
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

Templates
---------

It translates.

**Original**

```ruby
```

**Translated**

```ruby
```

It does not translate.

**Unchanged**

```ruby
```
