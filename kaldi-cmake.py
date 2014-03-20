#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import shutil
import platform
import re
#import random
from argparse import ArgumentParser

# --kaldi=..\kaldi-trunk --project=..\trunk
# --kaldi=../kaldi-trunk --project=../project/kaldi

sys_type = platform.system()

parser = ArgumentParser(prog = "kaldi-cmake", description = "Скрипт для создания файлов проекта под CMake.")
parser.add_argument ('-k', '--kaldi', default = os.getenv("KALDI_ROOT"), help = "Путь к директории с исходниками Kaldi.", metavar = 'DIR')
parser.add_argument ('-p', '--project', default = str(os.path.join(os.path.abspath(os.curdir), "project")), help = 'Путь к директории, в которой нужно создать проект.', metavar = 'DIR')
namespace = parser.parse_args(sys.argv[1:])
if namespace.kaldi == None:
    print("\nНеобходимо указать директорию с исходниками Kaldi.\n")
    exit(1)
print("Параметры запуска: {}\n".format(namespace))

g_trunk_src = str(os.path.join(os.path.abspath(namespace.kaldi), "src")).replace('\\', '/')
g_proj_src = os.path.abspath(namespace.project)

g_cmake_src = "cmake"
g_cmake_dst = os.path.join(g_proj_src, "cmake")
g_externals_src = "externals"
g_externals_dst = os.path.join(g_proj_src, "externals")
g_patched_src = None
if sys_type == "Linux":
    g_patched_src = "patched_linux"
else:
    g_patched_src = "patched_windows"
g_patched_dst = g_proj_src
g_cmake_hdr = "CMakeLists.txt"

g_inc_name = "include"
g_src_name = "src"
g_tst_name = "test"

#g_allowed = ["base", "cudamatrix", "feat", "lm", "matrix", "nnet", "tree", "util"]
g_allowed_bin = ["bin"]
g_allowed_lib = [
    "decoder", "transform", "nnet", "nnet2", "lat", "hmm", "ivector", "sgmm", "sgmm2", "gmm",
    "thread", "tree", "feat", "lm", "util", "cudamatrix", "matrix", "fstext", "base"
]
g_excl_dir = ["doc", "gst-plugin", "makefiles", "online", "onlinebin"]
g_excl_src = [
    "compute-kaldi-pitch-feats.cc",
    "copy-feats-to-htk.cc",
    "copy-feats-to-sphinx.cc",
    "cu-device.cc",
    "kaldi-io-test.cc",
    "kaldi-table-test.cc",
    "nnet-component-test.cc",
    "online-audio-client.cc",
    "online-audio-server-decode-faster.cc",
    "online-tcp-source.cc",
    "process-kaldi-pitch-feats.cc",
    "timer.h"
]
g_external = None
if sys_type == "Linux":
    g_external = {"fst":None, "irstlm":None}
else:
    g_external = {"fst":"fst", "irstlm":None}

g_inc_dir = os.path.join(g_proj_src, g_inc_name)
g_src_dir = os.path.join(g_proj_src, g_src_name)
g_tst_dir = os.path.join(g_proj_src, g_tst_name)
g_hdr_cmake = os.path.join(g_proj_src, "CMakeHeaderFileList.cmake")
g_src_cmake = os.path.join(g_proj_src, "CMakeSourceFileList.cmake")
g_lst_cmake = os.path.join(g_proj_src, "CMakeLists.txt")
g_mod_sorted = os.path.join(g_proj_src, "mod_sorted.txt")

class KaldiFile:
    ref_path = None
    header = None
    depends = None
    
    def __init__(self, _file_path, _ref_path, _header):
        self.ref_path = str(_ref_path).replace('\\', '/')
        self.header = _header
        self.depends = set()
        with open(_file_path, "r", encoding="utf-8") as file_src:
            lines = file_src.readlines()
            file_src.close()
        for line in lines:
            match = re.search(r"^#include\s+\"[./]*([^\./\"]+)/[^/\"]+\"", line)
            if match:
                self.depends.add(match.groups()[0])

class KaldiModule:
    name = None
    var_hdr = None
    var_src = None
    exe_mod = None
    tst_mod = None
    hdr_lst = None
    src_lst = None
    depends = None

    def __init__(self, _name, _exe_mod, _tst_mod):
        self.name = _name
        self.var_hdr = "HEADER_" + re.sub("-", "_", _name).upper()
        self.var_src = "SRC_" + re.sub("-", "_", _name).upper()
        self.exe_mod = _exe_mod
        self.tst_mod = _tst_mod
        self.hdr_lst = []
        self.src_lst = []
        self.depends = set()
    
    def Append(self, _file):
        if _file.header:
            self.hdr_lst.append(_file)
        else:
            self.src_lst.append(_file)
        self.depends = self.depends.union(_file.depends)
        
    def WriteHdr(self, _lines):
        if len(self.hdr_lst) > 0:
            _lines.append("\nset (" + self.var_hdr)
            for header in self.hdr_lst:
                _lines.append("\t" + header.ref_path)
            _lines.append(")")

    def WriteSrc(self, _lines):
        if len(self.src_lst) > 0:
            _lines.append("\nset (" + self.var_src)
            for source in self.src_lst:
                _lines.append("\t" + source.ref_path)
            _lines.append(")")

def CopyTree(_dir_src, _dir_dst):
    for root, dirs, files in os.walk(_dir_src):
        for name in files:
            path_src = os.path.join(root, name)
            path_dst = str(path_src).replace(_dir_src, _dir_dst)
            if os.path.exists(path_dst):
                os.remove(path_dst)
            shutil.copyfile(path_src, path_dst)

def IsApplication(_path):
    lines = []
    with open(_path, "r", encoding="utf-8") as file_src:
        lines = file_src.readlines()
        file_src.close()
    for line in lines:
        match = re.search("^\\s*int\\s*main\\s*\\(", line)
        if match:
            return True
    return False

def IsAllowed(_module):
    #print(_module.name + " - " + _module.src_lst[0].ref_path)
    for depend in module.depends:
        if not (depend in g_allowed_bin) and not (depend in g_allowed_lib) and not (depend in g_external):
            #print("    - depend: " + depend)
            return False
    for src_file in _module.src_lst:
        if os.path.basename(src_file.ref_path) in g_excl_src:
            #print("    - ref_path: " + src_file.ref_path)
            return False
    return True

def AddStaticLibrary(_file, _module):
    _file.write("\nadd_library(" + _module.name + " STATIC ${" + _module.var_src + "} ${" + _module.var_hdr + "})\n")
    _file.write("set_default_library_target_properties(" + _module.name + ")\n")

def AddExecutable(_file, _module, _headers, _regist):
    mod_name = os.path.basename(_module.src_lst[0].ref_path)
    mod_name = os.path.splitext(mod_name)[0]
    if mod_name in g_excl_dir:
        return
    if mod_name in _regist:
        _regist[mod_name] = _regist[mod_name] + 1
        mod_name = mod_name + "-" + str(_regist[mod_name])
    else:
        _regist[mod_name] = 1
    _file.write("\nadd_executable(" + mod_name + " " + _module.src_lst[0].ref_path + ")\n")
    _file.write("set_default_executable_target_properties(" + mod_name + ")\n")
    for depend in g_external:
        if g_external[depend] != None:
            _file.write("import_shared_library(" + mod_name + " " + depend + ")\n")
    for depend in g_allowed_lib:
        if not (depend in _headers):
            _file.write("import_static_library(" + mod_name + " " + depend + ")\n")
    _file.write("if (UNIX)\n")
    _file.write("\ttarget_link_libraries(" + mod_name + " ${Boost_LIBRARIES} ${ATLASLIBS} ${OPENFSTLIBS} rt dl)\n")
    _file.write("else()\n")
    _file.write("\ttarget_link_libraries(" + mod_name + " ${Boost_LIBRARIES} ${MKL_LIBRARIES})\n")
    _file.write("endif()\n")

print("======= BEGIN =======")

#if os.path.exists(g_proj_src):
#    print("Удаление директории: " + g_proj_src)
#    shutil.rmtree(g_proj_src, True)
print("Копирование директории: " + g_cmake_src)
shutil.copytree(g_cmake_src, g_cmake_dst)
#print("Копирование директории: " + g_externals_src)
#shutil.copytree(g_externals_src, g_externals_dst)
print("Создание директории: " + g_inc_dir)
os.mkdir(g_inc_dir)
print("Создание директории: " + g_src_dir)
os.mkdir(g_src_dir)
print("Создание директории: " + g_tst_dir)
os.mkdir(g_tst_dir)

lib_modules = []
exe_modules = []
tst_modules = []
dir_lst = os.listdir(g_trunk_src)
for dir_name in dir_lst:
    if dir_name in g_excl_dir:
        continue
    mod_src_dir = os.path.join(g_trunk_src, dir_name)
    if os.path.isfile(mod_src_dir):
        continue
    if dir_name[0] == '.':
        continue
    inc_dir = os.path.join(g_inc_dir, dir_name)
    src_dir = os.path.join(g_src_dir, dir_name)
    tst_dir = os.path.join(g_tst_dir, dir_name)
    os.mkdir(inc_dir)
    os.mkdir(src_dir)
    os.mkdir(tst_dir)
    lib_module = KaldiModule(dir_name, False, False)
    file_lst = os.listdir(mod_src_dir)
    for file_name in file_lst:
        parts = os.path.splitext(file_name)
        if len(parts) != 2:
            continue
        file_ext = parts[1].lower()
        header = False
        if file_ext == ".h":
            header = True
        elif file_ext != ".cc":
            continue
        file_src = os.path.join(mod_src_dir, file_name)
        if header:
            shutil.copy(file_src, inc_dir)
            lib_module.Append(KaldiFile(file_src, os.path.join(g_inc_name, dir_name, file_name), True))
        else:
            if IsApplication(file_src):
                match = re.search("-test\\...$", file_name)
                if match:
                    shutil.copy(file_src, tst_dir)
                    module = KaldiModule(dir_name, True, True)
                    module.Append(KaldiFile(file_src, os.path.join(g_tst_name, dir_name, file_name), False))
                    tst_modules.append(module)
                else:
                    shutil.copy(file_src, src_dir)
                    module = KaldiModule(dir_name, True, False)
                    module.Append(KaldiFile(file_src, os.path.join(g_src_name, dir_name, file_name), False))
                    exe_modules.append(module)
            else:
                shutil.copy(file_src, src_dir)
                lib_module.Append(KaldiFile(file_src, os.path.join(g_src_name, dir_name, file_name), False))
    if len(lib_module.hdr_lst) > 0:
        lib_modules.append(lib_module)

for module in lib_modules:
    module.depends.discard(module.name)
    for ext_name in g_external:
        module.depends.discard(ext_name)
hdr_only = []
for module in lib_modules:
    if len(module.src_lst) == 0:
        hdr_only.append(module.name)
        g_allowed_lib.append(module.name)
for modules in [lib_modules, exe_modules, tst_modules]:
    for module in modules:
        for mod_name in hdr_only:
            module.depends.discard(mod_name)
modules = []
for module in lib_modules:
    if module.name in g_allowed_lib:
        modules.append(module)
lib_modules = modules

lines = []
for module in lib_modules:
    module.WriteHdr(lines)
with open(g_hdr_cmake, "w", encoding="utf-8") as file_txt:
    for line in lines:
        file_txt.write(line + "\n")
    file_txt.close()

lines = []
for module in lib_modules:
    module.WriteSrc(lines)
with open(g_src_cmake, "w", encoding="utf-8") as file_txt:
    for line in lines:
        file_txt.write(line + "\n")
    file_txt.close()

regist = dict()
lines = []
with open(g_cmake_hdr, "r", encoding="cp1251") as file_txt:
    lines = file_txt.readlines()
    file_txt.close()
with open(g_lst_cmake, "w", encoding="utf-8") as file_txt:
    for line in lines:
        file_txt.write(line.rstrip() + "\n")
    for module in lib_modules:
        if not (module.name in hdr_only):
            AddStaticLibrary(file_txt, module)
    for module in exe_modules:
        if IsAllowed(module):
            AddExecutable(file_txt, module, hdr_only, regist)
    #for module in tst_modules:
    #    if IsAllowed(module):
    #        AddExecutable(file_txt, module, hdr_only, regist)
    file_txt.close()

print("Копирование директории: " + g_patched_src)
CopyTree(g_patched_src, g_patched_dst)

print("======= END =======")
