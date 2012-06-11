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
        new_object = __import__(module, globals(), locals(), attributes, -1)
        from_file = inspect.getfile(new_object)

        if from_file.endswith('.pyc'):
            return from_file[:-1]
        elif from_file.endswith('.py'):
            return from_file

    def get_line(self):
        return vim.current.line

    def find_import(self):
        line = self.get_line()

        if line.startswith('from') or line.startswith('import'):

            if line.startswith('from'):
                statment, module, importer, attribute = line.split(' ')
                attributes = attribute.split(',')
            else:
                statement, module = line.split(' ')
                attributes = []

            return self.get_import_file(module, attributes=attributes)
        else:
            print "Cant open docs for this"

finder = SourceFinder()
filename = finder.find_import()

if filename:
    vim.command('return "%s"' % (filename))
EOF
endfunction

function! python#SourceTab()
    let filename = s:FindPythonSource()
    exec 'tabnew '.filename
endfunction

function! python#SourceSplit()
    let filename = s:FindPythonSource()
    exec 'split '.filename
endfunction

function! python#SourceVSplit()
    let filename = s:FindPythonSource()
    exec 'vsplit '.filename
endfunction

nmap <leader>sft :call python#SourceTab()<CR>
nmap <leader>sfs :call python#SourceSplit()<CR>
nmap <leader>sfv :call python#SourceVSplit()<CR>
