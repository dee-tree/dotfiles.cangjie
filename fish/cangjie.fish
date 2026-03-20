
function cjworkspace --description "setup cangjie workspace"
    set -gx CJ_WORKSPACE "$(eval echo ~$USER)/projects/cangjie"
    if set -q $argv[1]
        set CJ_WORKSPACE $argv[1]
    end
    set -gx CJ_OUT "$CJ_WORKSPACE/out"
end

cjworkspace

function cjenv --description "setup built cangjie"
    set -gx CANGJIE_HOME $CJ_OUT

    if count $argv > 0
        set CANGJIE_HOME $argv[1]
    end

    set -l hw_arch $(arch)
    if [ $hw_arch = "" ]
        set hw_arch "x86_64"
    end

    echo "Activating cangjie at $CANGJIE_HOME"
    fish_add_path --prepend -g {$CANGJIE_HOME}/bin
    fish_add_path --prepend -g {$CANGJIE_HOME}/tools/bin
    fish_add_path --append -g {$HOME}/.cjpm/bin
    set -gxp LD_LIBRARY_PATH $CANGJIE_HOME/runtime/lib/linux_{$hw_arch}_cjnative
    set -gxp LD_LIBRARY_PATH $CANGJIE_HOME/tools/lib
end

function cjcbuild --description "build cjc"
    set -l cjc_dir "$CJ_WORKSPACE/cangjie_compiler"
    pushd $cjc_dir
    python3 build.py build -t debug --enable-assert --no-tests --jobs=16
        or return 1

    python3 build.py install --prefix $CJ_OUT
        or return 1
    popd
end

function cjruntimebuild --description "build cj runtime"
    set -l dir "$CJ_WORKSPACE/cangjie_runtime/runtime"
    pushd $dir
    python3 build.py build -t debug --version 1.0.0
        or return 1
    python3 build.py install
        or return 1
    python3 build.py install --prefix $CJ_OUT
        or return 1
    popd
end

function cjstdbuild --description "build cj stdlib"
    set -l runtime_dir "$CJ_WORKSPACE/cangjie_runtime/runtime/output"
    set -l dir "$CJ_WORKSPACE/cangjie_runtime/stdlib"
    pushd $dir
    python3 build.py build -t debug --target-lib $runtime_dir
        or return 1
    python3 build.py install --prefix $CJ_OUT
         or return
    popd
end

function cjstdxbuild --description "build cj stdx"
    set -l dir "$CJ_WORKSPACE/cangjie_stdx"
    pushd $dir
    python3 build.py clean
        or return 1
    python3 build.py build -t debug
        or return 1
    python3 build.py install --prefix $CJ_OUT
        or return 1
    popd

    set -gx CANGJIE_STDX_PATH "$CJ_OUT/linux_x86_64_cjnative/static/stdx"
end

function cjcjpmbuild --description "build cjpm"
    set -l dir "$CJ_WORKSPACE/cangjie_tools/cjpm"
    pushd $dir
    python3 build/build.py build -t debug
        or return 1
    python3 build/build.py install --prefix $CJ_OUT
        or return 1
    popd
    # ln -s $CJ_OUT/cjpm $CJ_OUT/bin/cjpm
end

function cjinteropbuild --description "build interoplib"
    # builds objc part here
    set -l objc_dir "$CJ_WORKSPACE/cangjie_multiplatform_interop/objc"

    pushd $objc_dir/build
    python3 build.py build -t debug --target linux_x86_64_cjnative
    or return 1
    python3 build.py install --target linux_x86_64_cjnative --prefix $CJ_OUT
    or return 1
    popd
end

function cjbuild --description "build cangjie toolchain"
    cjcbuild
    cjruntimebuild
    cjstdbuild
end

function cjtest --description "test cangjie"
    set -l cj_test_dir $CJ_WORKSPACE/cangjie_test
    set -l cj_tf_dir $CJ_WORKSPACE/cangjie_test_framework
    set -l test_cfg $cj_test_dir/testsuites/LLT/configs/cjnative/cjnative_test.cfg
    set -l test_list $cj_test_dir/testsuites/LLT/cjnative_testlist
    
    set -l test_tmp_dir $cj_tf_dir/test_temp
    set -l logcjtestdir ~/logs/cjtest
    set -l test_cases $argv[(count argv)]
    set -l test_kind "LLT"

    if string match '*HLT/*' $test_cases 
        set test_cfg $cj_test_dir/testsuites/HLT/configs/cjnative/cangjie2cjnative_linux_x86_test.cfg
        set test_list $cj_test_dir/testsuites/HLT/testlist
        set test_kind "HLT"
    end
    
    rm -rf $test_tmp_dir
    rm -rf $logcjtestdir

    set -l test_list_opt "--test_list=$test_list"

    pushd $CJ_WORKSPACE
    echo "Running $test_kind tests..."

    echo "command: python3 $cj_tf_dir/main.py --temp_dir=$test_tmp_dir --log_dir=$logcjtestdir --test_cfg=$test_cfg $test_list_opt --fail-verbose -pFAIL -j8 --debug $test_cases"
    python3 cangjie_test_framework/main.py --temp_dir=$test_tmp_dir --log_dir=$logcjtestdir --test_cfg=$test_cfg $test_list_opt --fail-verbose -pFAIL -j8 --debug $test_cases 
    popd
end
