def literal_is_not_nil
  s = "Hello"
  # s must not "go bad"
  s = Ops.add(s, "World")
end

def translated_literal_is_not_nil
  s = _("Hello")
  s = Ops.add(s, _("World"))
end

def condition_checks_value_is_not_nil(s)
  if s != nil
    s2 = Ops.add(s, "foo")
  end
end

# CANNOT do
def foo(a)
  b = Ops.add(a, 1)
end

