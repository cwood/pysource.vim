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

class PythonFinder(object):

    def get_import_file(self, module, attributes=None, **kwargs):
        new_object = __import__(module, globals(), locals(), [attributes], -1)
        from_file = inspect.getfile(new_object)
        return from_file[:-1]

    def get_line(self):
        return vim.current.line

    def find_import(self):
        line = self.get_line()

        if line.startswith('from') or line.startswith('import'):

            if line.startswith('from'):
                statment, module, importer, attribute = line.split(' ')
            else:
                statement, module = line.split(' ')
                attribute = None

            return self.get_import_file(module, attributes=attribute)
        else:
            print "Cant open docs for this"

finder = PythonFinder()
filename = finder.find_import()
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
