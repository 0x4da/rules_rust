"""Unittests for rust rules."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//rust:defs.bzl", "rust_binary", "rust_library", "rust_proc_macro", "rust_shared_library", "rust_static_library")

def _assert_cc_info_has_library_to_link(env, tut, type):
    asserts.true(env, CcInfo in tut, "rust_library should provide CcInfo")
    cc_info = tut[CcInfo]
    linker_inputs = cc_info.linking_context.linker_inputs.to_list()
    asserts.equals(env, len(linker_inputs), 1)
    library_to_link = linker_inputs[0].libraries[0]
    asserts.equals(env, False, library_to_link.alwayslink)

    asserts.equals(env, [], library_to_link.lto_bitcode_files)
    asserts.equals(env, [], library_to_link.pic_lto_bitcode_files)

    asserts.equals(env, [], library_to_link.objects)
    asserts.equals(env, [], library_to_link.pic_objects)

    if type  == "cdylib":
        asserts.true(env, library_to_link.dynamic_library != None)
        asserts.equals(env, None, library_to_link.interface_library)
        asserts.true(env, library_to_link.resolved_symlink_dynamic_library != None)
        asserts.equals(env, None, library_to_link.resolved_symlink_interface_library)
        asserts.equals(env, None, library_to_link.static_library)
        asserts.equals(env, None, library_to_link.pic_static_library)
    else:
        asserts.equals(env, None, library_to_link.dynamic_library)
        asserts.equals(env, None, library_to_link.interface_library)
        asserts.equals(env, None, library_to_link.resolved_symlink_dynamic_library)
        asserts.equals(env, None, library_to_link.resolved_symlink_interface_library)
        asserts.true(env, library_to_link.static_library != None)
        asserts.true(env, library_to_link.pic_static_library != None)
        asserts.equals(env, library_to_link.static_library, library_to_link.pic_static_library)

def _rlib_provides_cc_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)
    _assert_cc_info_has_library_to_link(env, tut, "rlib")
    return analysistest.end(env)

def _bin_does_not_provide_cc_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)
    asserts.false(env, CcInfo in tut, "rust_binary should not provide CcInfo")
    return analysistest.end(env)

def _proc_macro_does_not_provide_cc_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)
    asserts.false(env, CcInfo in tut, "rust_proc_macro should not provide CcInfo")
    return analysistest.end(env)

def _cdylib_provides_cc_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)
    _assert_cc_info_has_library_to_link(env, tut, "cdylib")
    return analysistest.end(env)

def _staticlib_provides_cc_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    tut = analysistest.target_under_test(env)
    _assert_cc_info_has_library_to_link(env, tut, "staticlib")
    return analysistest.end(env)

rlib_provides_cc_info_test = analysistest.make(_rlib_provides_cc_info_test_impl)
bin_does_not_provide_cc_info_test = analysistest.make(_bin_does_not_provide_cc_info_test_impl)
staticlib_provides_cc_info_test = analysistest.make(_staticlib_provides_cc_info_test_impl)
cdylib_provides_cc_info_test = analysistest.make(_cdylib_provides_cc_info_test_impl)
proc_macro_does_not_provide_cc_info_test = analysistest.make(_proc_macro_does_not_provide_cc_info_test_impl)

def _cc_info_test():
    rust_library(
        name = "rlib",
        srcs = ["foo.rs"],
    )

    rust_binary(
        name = "bin",
        srcs = ["foo.rs"],
    )

    rust_static_library(
        name = "staticlib",
        srcs = ["foo.rs"],
    )

    rust_shared_library(
        name = "cdylib",
        srcs = ["foo.rs"],
    )

    rust_proc_macro(
        name = "proc_macro",
        srcs = ["proc_macro.rs"],
        edition = "2018",
    )

    rlib_provides_cc_info_test(
        name = "rlib_provides_cc_info_test",
        target_under_test = ":rlib",
    )
    bin_does_not_provide_cc_info_test(
        name = "bin_does_not_provide_cc_info_test",
        target_under_test = ":bin",
    )
    cdylib_provides_cc_info_test(
        name = "cdylib_provides_cc_info_test",
        target_under_test = ":cdylib",
    )
    staticlib_provides_cc_info_test(
        name = "staticlib_provides_cc_info_test",
        target_under_test = ":staticlib",
    )
    proc_macro_does_not_provide_cc_info_test(
        name = "proc_macro_does_not_provide_cc_info_test",
        target_under_test = ":proc_macro",
    )

def cc_info_test_suite(name):
    """Entry-point macro called from the BUILD file.

    Args:
        name: Name of the macro.
    """
    _cc_info_test()

    native.test_suite(
        name = name,
        tests = [
            ":rlib_provides_cc_info_test",
            ":staticlib_provides_cc_info_test",
            ":cdylib_provides_cc_info_test",
            ":proc_macro_does_not_provide_cc_info_test",
            ":bin_does_not_provide_cc_info_test",
        ],
    )
