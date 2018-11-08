# News

## unreleased

## 0.5, 2018-11-08

- zk: find all *.rb files in subdirectories if an argument is a directory
- Eager mode replacements:
    ```rb
    Builtins.size(foo)
    if Builtins.size(bar) == 0 || Builtins.size(qux) > 0
      Builtins.sformat("... %1 ...", val)
    end

    a = a + foo
    @b = @b * bar
    @@c = @@c - qux
    ```
    becomes
    ```rb
    foo.size
    if bar.empty? || !qux.empty?
      "... #{val} ..."
    end

    a += foo
    @b *= bar
    @@c -= baz
    ```

## 0.4, 2018-11-02

- Added zk -e, EagerRewriter (don't care about niceness, replace all)
- Recover from parse errors by reverting to the original file
- Fixed reporting unhandled node types
- Handle keyword arguments, regex match

## 0.3, 2014-12-02

- bin/count_method_calls added

## 0.2, 2014-11-28

- first release as a gem
