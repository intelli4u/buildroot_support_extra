#!/usr/bin/env python

import glob
import re
import os
import optparse
import sys


def secure_name(name):
    return name and name.replace('-', '_').upper()


def escape_var(variable):
    var = None

    while var != variable:
       var = variable
       match = re.match('\$\(([A-Za-z0-9_]+)\)', var)
       if match:
           val = match.group(1)
           subvar = os.environ.get(val, '')
           variable = var.replace('$(%s)' % val, subvar)

    return variable


def parse_override(ret, line):
    if ':' in line and '*' in line:
        print 'Error: both name and globbing used in line: %s' % line
        return

    if ':' in line:
        name, path = line.split(':', 1)
        ret[secure_name(name)] = escape_var(path)
    else:
        globbing = glob.glob(escape_var(line))
        if not globbing:
            print 'Error: no match globbing for %s' % line

        for path in globbing:
            ret[secure_name(os.path.basename(path))] = path


def parse_variable(variables, line):
    match = re.match('^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', line)
    if match:
        variables[match.group(1)] = escape_var(match.group(2))


def parse_variables(variables, line):
    # TODO: support space inside the value
    for pair in re.split('\s+', line):
        parse_variable(variables, pair)


def parse_global_config(override, override2, variables, filename):
    with open(filename, "r") as fp:
        action = 'var'

        for line in fp:
            li = line.strip()
            if not li:
                continue

            if li.startswith('#'):
                comment = li[1:].lstrip()
                if comment == 'override':
                    action = 'over'
                elif comment == 'override2':
                    action = 'over2'
                elif comment == 'variable':
                    action = 'var'

                continue

            if action == 'over':
                parse_override(override, li)
            elif action == 'over2':
                parse_override(override2, li)
            elif action == 'var':
                parse_variable(variables, li)


def dump_var(filename, override, override2, variables):
    def dump(fp, dvals=None, export=False):
        if dvals is None:
            fp.write('\n')
        else:
            for key in sorted(dvals.keys()):
                fp.write(
                    '%s%s=%s\n' % (
                         'export ' if export else '',
                         key, dvals[key]))

    def build_override(override, override2):
        ret = dict()

        for key, value in override.items():
            if key not in override2:
                ret['%s_OVERRIDE_SRCDIR' % key] = value

        return ret

    def build_override2(override2):
        ret = dict()

        for key, value in override2.items():
            ret['%s_OVERRIDE2_SRCDIR' % key] = value

        return ret


    if not filename:
        return

    with open(filename, 'w') as fp:
        dump(fp, variables, export=True)

        dump(fp)
        dump(fp, build_override(override, override2))
        dump(fp, build_override2(override2))


parser = optparse.OptionParser("""\
%prog [option] args

Converts the config files into variables with values in makefile-style.

It handles three parts for package override, override2 (extended override)
and variables used globally during the compilation. The config file contains
sections starting with specific words to indicate the following contents.

# override
...
# override2
...
# variable
...

both "override" and "override2" accept the syntax of Python glob. And all
three parts support variable expanding, whose values are fetched from the
environment. If the value isn't defined, an empty string will be used.""")

parser.add_option(
    '-c', '--config',
    dest='config', action='store',
    help='Provides the config pairs for the environment variables')
parser.add_option(
    '-r', '--root-dir',
    dest='root', action='store',
    help='Set the root of the project for project globbing')

if __name__ == '__main__':
    override, override2 = dict(), dict()
    variables = dict({'BR2_USE_BUILDROOT': 'y'})

    argc = 0

    opt, args = parser.parse_args()
    if len(args) > 1:
        output = args[0]
        argc += 1

    if opt.root:
        os.chdir(opt.root)

    for config in args[argc:]:
        parse_global_config(override, override2, variables, config)

    if opt.config:
        parse_variables(variables, opt.config.strip('\'"'))

    dump_var(output, override, override2, variables)

