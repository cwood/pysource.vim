" pysource.vim - Find python source intelligently
" Maintainer: Colin Wood <cwood06 at gmail dot com>
" Version: 0.2.0a
" Bugs: Relative imports not opening up okay
" License: Same as Vim

if has('g:pysource_loaded')
    finish
endif

let g:pysource_loaded = 1

if !has('python')
    echoerr 'Missing python'
    finish
endif

function! s:FindPythonSource()
python << EOF
import vim
import inspect
import os
import sys

class SourceFinder(object):

    def get_import_file(self, module, attributes=[], **kwargs):

        try:
            new_object = __import__(module, globals(), locals(), attributes, -1)
        except:
            return ''

        from_file = inspect.getfile(new_object)

        if from_file.endswith('.pyc'):
            return from_file[:-1]
        elif from_file.endswith('.py'):
            return from_file

    def get_line(self):
        return vim.current.line

    def find_import(self):
        line = self.get_line()
        parts = line.split(' ')

        try:
            module = parts[1]
        except KeyError:
            module = None

        try:
            attributes = parts[3]
            attributes = attributes.split(',')
        except KeyError:
            attributes = []

        return self.get_import_file(module, attributes=attributes)

finder = SourceFinder()
filename = finder.find_import()

if filename:
    vim.command('return "%s"' % (filename))
EOF
endfunction

function! python#Source(type)
    let filename = s:FindPythonSource()

    if filename == ''
        echoerr "Could not open source"
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

nmap <leader>sft :call python#Source('tab')<CR>
nmap <leader>sfs :call python#Source('split')<CR>
nmap <leader>sfv :call python#Source('vsplit')<CR>
