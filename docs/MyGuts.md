# NAME

Module::Starter::Plugin::MyGuts - module starter with opinionated settings

# SYNOPSIS

In your `~/.module-starter/config`:

```
builder:      ExtUtils::MakeMaker
license:      MIT_0
genlicense:   1
ignores_type: git manifest
author:       author <author@email>
minperl:      v5.40.0
verbose:      1
plugins:      Module::Starter::Plugin::MyGuts
```

Then, run:

```shell
$ module-starter --module=Foo::Bar
```

Alternatively:

```shell
$ module-starter \
    --module=Foo::Bar \
    --eumm \
    --license=MIT_0 \
    --genlicense \
    --ignores=git,manifest \
    --author='author <author@email>' \
    --minperl=v5.40.0 \
    --verbose \
    --plugin=Module::Starter::Plugin::MyGuts
```

# DESCRIPTION

This plugin is a subclass of [Module::Starter::Simple](https://metacpan.org/pod/Module%3A%3AStarter%3A%3ASimple) that replaces some of its
**\*\_guts** methods with my preferred settings, thus not intended for public usage.
Inspired by [Module::Starter::Plugin::Template](https://metacpan.org/pod/Module%3A%3AStarter%3A%3APlugin%3A%3ATemplate).

Note that only [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils%3A%3AMakeMaker) and single author are supported for simplicity.

# METHODS

## new(*%args*)

Calls the `new` `SUPER` method.

## post\_create\_distro

If `github` is set, creates the .github/workflows directory and calls `create_CI()`,
creates the docs directory (intended to contain POD files from distribution converted
to Markdown), and then calls `create_README_md()`.

## create\_CI ( *&#36;self, &#36;fpath* )

If `github` is set, creates the distribution's `ci.yml` file in .github/workflows
directory.

## create\_README\_md

If `github` is set, creates the distribution's `README.md` file.

## \*\_guts

These [Module::Starter::Simple](https://metacpan.org/pod/Module%3A%3AStarter%3A%3ASimple) methods are subclassed to look like this:

```perl
sub module_guts ( $self, @args )
{
    ...
}
```

- module\_guts
- Makefile\_PL\_guts
- Makefile\_PL\_meta\_merge
- Changes\_guts
- README\_guts
- t\_guts
- xt\_guts
- ignores\_guts

## create\_file( *&#36;fname, @content\_lines* )

Overrides `Module::Starter::Simple::create_file()` so files are created with UTF-8
encoding accordingly.

See ["create\_file(-&#36;fname,-@content\_lines-)" in Module::Starter::Simple](https://metacpan.org/pod/Module%3A%3AStarter%3A%3ASimple#create_file---fname---content_lines).

# CONFIGURATION

- **no\_minperl**

    If true, a minimum perl version is not declared in the files. Default: `undef`.

# BUGS

Report bugs at [https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts/issues](https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts/issues).

# AUTHOR

ryoskzypu <ryoskzypu@proton.me>

# SEE ALSO

- [Module::Starter](https://metacpan.org/pod/Module%3A%3AStarter)
- [Module::Starter::Simple](https://metacpan.org/pod/Module%3A%3AStarter%3A%3ASimple)
- [Module::Starter::Plugin::Template](https://metacpan.org/pod/Module%3A%3AStarter%3A%3APlugin%3A%3ATemplate)
- [https://neilb.org/2015/09/05/cpan-glossary.html](https://neilb.org/2015/09/05/cpan-glossary.html)
- [https://neilb.org/2015/10/18/spotters-guide.html](https://neilb.org/2015/10/18/spotters-guide.html)
- [https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/cpan-packaging.md](https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/cpan-packaging.md)
- [https://metacpan.org/pod/Dist::Zilla::Starter#CPAN-DISTRIBUTIONS](https://metacpan.org/pod/Dist::Zilla::Starter#CPAN-DISTRIBUTIONS)
- [https://metacpan.org/pod/Dist::Zilla::Starter#A-BRIEF-HISTORY-OF-AUTHORING](https://metacpan.org/pod/Dist::Zilla::Starter#A-BRIEF-HISTORY-OF-AUTHORING)
- [https://blogs.perl.org/users/neilb/2016/04/the-perl-toolchain-pause-and-cpan.html](https://blogs.perl.org/users/neilb/2016/04/the-perl-toolchain-pause-and-cpan.html)
- [https://blogs.perl.org/users/neilb/2016/04/the-perl-toolchain-developing-your-module.html](https://blogs.perl.org/users/neilb/2016/04/the-perl-toolchain-developing-your-module.html)
- [https://blogs.perl.org/users/tinita/2019/11/perl5-cpan-module-best-practices.html](https://blogs.perl.org/users/tinita/2019/11/perl5-cpan-module-best-practices.html)
- [https://github.com/cpan-authors/Release-Checklist/blob/master/Checklist.md](https://github.com/cpan-authors/Release-Checklist/blob/master/Checklist.md)

# COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.
