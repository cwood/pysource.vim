" pysource.vim - Find python source intelligently
" Maintainer: Colin Wood <cwood06 at gmail dot com>
" Version: 1.0.0
" License: Same as Vim

if has('g:pysource_loaded')
    finish
endif

if !has('python')
    echoerr 'Missing python'
    finish
endif

let g:pysource_loaded = 1

python << EOF
import vim
import inspect
import os
import sys
import re


def parse_import_line(line):

    parts, is_relative, relative_path = (line.split(' ', 3), False, None)

    try:
        module = parts[1]
    except KeyError:
        module = None

    if module.startswith('.'):
        paths = module.split('.')
        module = paths[-1]
        path = '.'.join(paths[0:-1])+'.'

        if path not in sys.path:
            sys.path.append(path)

        is_relative = True
        relative_path = path

    try:
        attributes = parts[3]
        attributes = attributes.split(',')
    except (IndexError, KeyError):
        attributes = ['']

    for i, attribute in enumerate(attributes):
        attributes[i] = re.sub(r'\s', '', attribute)

    return module, attributes, is_relative, relative_path


class SourceFinder(object):

    def __init__(self, module, is_relative=False, relative_path=None,
                *attributes):

        self.module = module

        if attributes:
            self.attributes =  attributes
        else:
            self.attributes = ['']

        self.is_relative = is_relative
        self.relative_path = relative_path

    def get_import_file(self, **kwargs):
        new_object = None

        try:
            new_object = __import__(self.module, globals(),
                                    locals(), self.attributes, -1)
        except Exception, e:

            if not getattr(self, 'is_relative', False):
                return e

        if getattr(self, 'is_relative', False):
            if os.path.exists(os.path.join(self.relative_path, self.module+'.py')):
                return os.path.join(self.relative_path, self.module+'.py')
            else:
                return ''

        if new_object:
            from_file = inspect.getfile(new_object)

            if from_file:
                if from_file.endswith('.pyc'):
                    return from_file[:-1]
                elif from_file.endswith('.py'):
                    return from_file

        return None

EOF


function! s:FindPythonSourceFromLine()
python << EOF
import vim
module, attributes, is_relative, relative_path = parse_import_line(vim.current.line)
finder = SourceFinder(module, is_relative, relative_path, *attributes)
filename = finder.get_import_file()

if isinstance(filename, Exception):
    vim.commaned('echoerr "Problem finding source: %s"' %(str(filename)))

if filename:
    vim.command('return "%s"' % (filename))
EOF
endfunction

function! python#Source(type)
    let filename = s:FindPythonSourceFromLine()

    if !filereadable(filename)
        echoerr "Could not open source. ".filename
    else
        if a:type == 'tab'
            exec 'tabnew '.filename
        elseif a:type == 'split'
            exec 'split '.filename
        elseif a:type == 'vsplit'
            exec 'vsplit '.filename
        endif
    endif
endfunction

function! python#findsource(pythonpath, ...)
python << EOF
import vim
import os

python_path_string = vim.eval('a:pythonpath')

finder = SourceFinder(python_path_string)
filename = finder.get_import_file()

if isinstance(filename, Exception):
    vim.command('echoerr "Got error: %s"' % (str(filename)))
elif filename and os.path.exists(filename):
    vim.command('edit %s' % (filename) )
else:
    vim.command('echoerr "Couldnt find source for %s"' % (python_path_string))
EOF
endfunction


nmap <leader>sft :call python#Source('tab')<CR>
nmap <leader>sfs :call python#Source('split')<CR>
nmap <leader>sfv :call python#Source('vsplit')<CR>

command! -nargs=1 PySource call python#findsource(<q-args>)
