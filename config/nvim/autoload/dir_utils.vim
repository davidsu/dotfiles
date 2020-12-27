function! s:cache_dir(key, value)
    if  a:value !~ a:key
        " key/value must have a parent/child relationship
        " we check if child matches parent since child path is the longest
        return
    endif
    let g:projectsRootDic[a:key] = a:value
    call SaveProjectsRootDic()
endfunction

function! dir_utils#cd_project_root_or_cache(projRoot)
    if has_key(g:projectsRootDic, a:projRoot)
        execute 'cd '.g:projectsRootDic[a:projRoot]
    else
        call s:cache_dir(a:projRoot, a:projRoot)
        execute 'cd '.a:projRoot
        return
    endif
endfunction

function! dir_utils#CdOnBufferEnter(isDirChange)
    if exists('g:cancelAutoCd')
        return
    endif
    if !exists('g:projectsRootDic')
        if exists('*GetProjectsRootDict')
            let g:projectsRootDic = call GetProjectsRootDict()
        else
            let g:projectsRootDic = {}
        endif
    endif
    let pwd = getcwd()
    let projRoot = utils#get_project_root(expand('%:p:h'))
    if pwd =~ '/node_modules/' || projRoot =~ '/node_modules/'
        return
    endif
    if !isdirectory(projRoot)
        return
    endif
    if a:isDirChange
        call s:cache_dir(projRoot, pwd)
        return
    endif
    if pwd =~ 'config/nvim/plugged'
        call dir_utils#cd_project_root_or_cache(projRoot)
        return
    endif
    if pwd == projRoot || pwd =~ projRoot.'/' 
        "this means that getcwd() is a child of projRoot..."
        "remember which directory we want when comming to the current project
        call s:cache_dir(projRoot, pwd)
        return
    endif
    call dir_utils#cd_project_root_or_cache(projRoot)
endfunction

