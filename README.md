# Module::Starter::Plugin::MyGuts

This plugin is a subclass of [Module::Starter::Simple](https://metacpan.org/pod/Module%3A%3AStarter%3A%3ASimple)
that replaces some of its **\*\_guts** methods with my preferred settings, thus
not intended for public usage. Inspired by [Module::Starter::Plugin::Template](https://metacpan.org/pod/Module%3A%3AStarter%3A%3APlugin%3A%3ATemplate).

Note that only [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils%3A%3AMakeMaker)
and single author are supported for simplicity.

## Installation

To download and install this module directly with [cpanminus](https://metacpan.org/pod/App::cpanminus):

```shell
$ cpanm https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts.git
```

To do it manually, run the following commands (after cloning the repository):

```shell
$ cd Module-Starter-Plugin-MyGuts
$ perl Makefile.PL
$ make
$ make test
$ make install
```

## Support and documentation

You can find documentation for this module in [docs](docs/) or with the
`perldoc` command (after installing):

```shell
$ perldoc Module::Starter::Plugin::MyGuts
```

You can also look for information at:

- GitHub issue tracker (report bugs here)

    https://github.com/ryoskzypu/Module-Starter-Plugin-MyGuts/issues

- Search CPAN

    https://metacpan.org/dist/Module-Starter-Plugin-MyGuts

## Copyright

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.
