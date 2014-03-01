#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
#import sys
import shutil
import re
#import random

g_kaldi_trunk_src_dir = "../kaldi-trunk/src"
g_dst_dir = "project/kaldi"
g_cmake_src = "cmake"
g_cmake_dst = os.path.join(g_dst_dir, "cmake")
g_cmake_hdr = "CMakeLists.txt"

g_inc_name = "include"
g_src_name = "src"
g_tst_name = "test"

g_exclude = ["doc", "gst-plugin", "makefiles", "online", "onlinebin"]
g_external = ["fst", "irstlm"]
g_top_mod = ["base", "itf"]
g_include = ["decoder"]
g_import = ["base"]

g_inc_dir = os.path.join(g_dst_dir, g_inc_name)
g_src_dir = os.path.join(g_dst_dir, g_src_name)
g_tst_dir = os.path.join(g_dst_dir, g_tst_name)
g_hdr_cmake = os.path.join(g_dst_dir, "CMakeHeaderFileList.cmake")
g_src_cmake = os.path.join(g_dst_dir, "CMakeSourceFileList.cmake")
g_lst_cmake = os.path.join(g_dst_dir, "CMakeLists.txt")
g_mod_sorted = os.path.join(g_dst_dir, "mod_sorted.txt")

class KaldiFile:
    ref_path = None
    header = None
    depends = None
    
    def __init__(self, _file_path, _ref_path, _header):
        self.ref_path = _ref_path
        self.header = _header
        self.depends = set()
        with open(_file_path, "r", encoding="utf-8") as file_src:
            lines = file_src.readlines()
            file_src.close()
        for line in lines:
            match = re.search("^#include\\s+[\"\\./]([^\\./\"]+)/", line)
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

def AddStaticLibrary(_file, _module):
    _file.write("\nadd_library(" + _module.name + " STATIC ${" + _module.var_src + "} ${" + _module.var_hdr + "})\n")
    _file.write("set_default_library_target_properties(" + _module.name + ")\n")
    for depend in _module.depends:
        _file.write("import_static_library(" + _module.name + " " + depend + ")\n")
    for depend in g_import:
        if not (depend in _module.depends):
            _file.write("import_static_library(" + _module.name + " " + depend + ")\n")

def AddExecutable(_file, _module, _regist):
    mod_name = os.path.basename(_module.src_lst[0].ref_path)
    mod_name = os.path.splitext(mod_name)[0]
    if mod_name in _regist:
        _regist[mod_name] = _regist[mod_name] + 1
        mod_name = mod_name + "-" + str(_regist[mod_name])
    else:
        _regist[mod_name] = 1
    _file.write("\nadd_executable(" + mod_name + " " + _module.src_lst[0].ref_path + ")\n")
    _file.write("set_default_executable_target_properties(" + mod_name + ")\n")
    _file.write("import_static_library(" + mod_name + " " + _module.name + ")\n")
    for depend in _module.depends:
        _file.write("import_static_library(" + mod_name + " " + depend + ")\n")
    for depend in g_import:
        if not (depend in _module.depends):
            _file.write("import_static_library(" + mod_name + " " + depend + ")\n")
    _file.write("target_link_libraries(" + mod_name + " ${ATLASLIBS} ${OPENFSTLIBS} rt dl)\n")

print("======= BEGIN =======")

if os.path.exists(g_dst_dir):
    print("Удаление директории: " + g_dst_dir)
    shutil.rmtree(g_dst_dir, True)
print("Копирование директории: " + g_cmake_src)
shutil.copytree(g_cmake_src, g_cmake_dst)
print("Создание директории: " + g_inc_dir)
os.mkdir(g_inc_dir)
print("Создание директории: " + g_src_dir)
os.mkdir(g_src_dir)
print("Создание директории: " + g_tst_dir)
os.mkdir(g_tst_dir)

lib_modules = []
exe_modules = []
tst_modules = []
dir_lst = os.listdir(g_kaldi_trunk_src_dir)
for dir_name in dir_lst:
    if dir_name in g_exclude:
        continue
    mod_src_dir = os.path.join(g_kaldi_trunk_src_dir, dir_name)
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

for modules in [lib_modules, exe_modules, tst_modules]:
    for module in modules:
        module.depends.discard(module.name)
        for ext_name in g_external:
            module.depends.discard(ext_name)
hdr_only = []
for module in lib_modules:
    if len(module.src_lst) == 0:
        hdr_only.append(module.name)
for modules in [lib_modules, exe_modules, tst_modules]:
    for module in modules:
        for mod_name in hdr_only:
            module.depends.discard(mod_name)

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

mod_depends = dict()
for module in lib_modules:
    if module.name in mod_depends:
        mod_depends[module.name] = mod_depends[module.name].union(module.depends)
    else:
        mod_depends[module.name] = set(module.depends)

dict_temp = dict()
for name, depends in mod_depends.items():
    dict_temp[name] = set(depends)
    for ext_name in g_external:
        dict_temp[name].discard(ext_name)
mod_sorted = []
for min_key in g_top_mod:
    mod_sorted.append(min_key)
    del dict_temp[min_key]
    for name, depends in dict_temp.items():
        if min_key in depends:
            depends.remove(min_key)
while len(dict_temp) > 0:
    min_key = None
    min_len = 1000
    for name, depends in dict_temp.items():
        if min_len >= len(depends):
            min_key = name
            min_len = len(depends)
    if min_len > 0:
        print(min_key + " - " + str(min_len) + " : " + str(dict_temp[min_key]))
    else:
        print(min_key + " - " + str(min_len))
    mod_sorted.append(min_key)
    del dict_temp[min_key]
    for name, depends in dict_temp.items():
        if min_key in depends:
            depends.remove(min_key)

with open(g_mod_sorted, "w", encoding="utf-8") as file_txt:
    for name in mod_sorted:
        file_txt.write("\n" + name + "\n")
        for depend in mod_depends[name]:
            file_txt.write("\t" + depend + "\n")
    file_txt.close()

regist = dict()
lines = []
with open(g_cmake_hdr, "r", encoding="cp1251") as file_txt:
    lines = file_txt.readlines()
    file_txt.close()
with open(g_lst_cmake, "w", encoding="utf-8") as file_txt:
    for line in lines:
        file_txt.write(line.rstrip() + "\n")
    for module in g_include:
        file_txt.write("\ninclude_directories(\"" + os.path.join(os.path.abspath(g_inc_dir), module) + "\")\n")
    for name in mod_sorted:
        for module in lib_modules:
            if (module.name == name) and (len(module.src_lst) > 0):
                AddStaticLibrary(file_txt, module)
#    for module in exe_modules:
#        file_txt.write("\n" + module.name + "\n")
#        for source in module.src_lst:
#            file_txt.write("\t" + source.ref_path + "\n")
#        for depend in module.depends:
#            file_txt.write("\t" + depend + "\n")
    for name in mod_sorted:
        for module in tst_modules:
            if module.name == name:
                AddExecutable(file_txt, module, regist)
    file_txt.close()

print("======= END =======")

#exit()
#
#g_word_sil = "<SIL>"
#g_phone_sil = "SIL"
#g_utils_dir = "utils"
#
#class StrList:
#    lines = None
#
#    def __init__(self):
#        self.lines = []
#    
#    def Clear(self):
#        self.lines = []
#        
#    def Append(self, _line):
#        self.lines.append(_line)
#        
#    def Save(self, _path):
#        self.lines.sort()
#        with open(_path, "w", encoding="utf-8") as file_txt:
#            for line in self.lines:
#                file_txt.write(line + "\n")
#            file_txt.close()
#
#class WordInfo:
#    text = None
#    tran = None
#    word = None
#    
#    def __init__(self, _text, _tran, _word):
#        self.text = _text.lower()
#        self.tran = _tran
#        self.word = int(_word)
#
#def SortWordsById(_word):
#    return _word.word
#
#class Vocabulary:
#    words = None
#    
#    def __init__(self, _lines):
#        self.words = []
#        for line in _lines:
#            match = re.search("[Common]\\s*$", line)
#            if match:
#                break
#            match = re.search("^(.+)=(.+)#(\\d+)\\s*$", line)
#            if match:
#                self.words.append(WordInfo(match.groups()[0], match.groups()[1], match.groups()[2]))
#        self.words.sort(key=SortWordsById)
#        
#    def Text(self):
#        text = None
#        word_id = 0
#        for word in self.words:
#            if word.word == word_id:
#                if text == None:
#                    text = word.text
#                else:
#                    text = text + " " + word.text
#                word_id = word_id + 1
#        return text
#
#class FileInfo:
#    root = None
#    name = None
#    path = None
#    spkr = None
#    sent = None
#    vocb = None
#    text = None
#    
#    def __init__(self, _root, _name, _path, _spkr, _sent, _vocb):
#        self.root = _root
#        self.name = _name
#        self.path = _path
#        self.spkr = _spkr
#        self.sent = _sent
#        self.vocb = _vocb
#        self.text = _vocb.Text()
#
#class FileList(list):
#    def __init__(self):
#        list.__init__(self, [])
#        
#    def Load(self, _path_sdv, _path_wav):
#        list.__init__(self, [])
#        for root, dirs, files in os.walk(_path_sdv):
#            for name in files:
#                match = re.search("(\\d{3})_(\\d{5})\\.sdv$", name.lower())
#                if not match:
#                    continue
#                path_wav = os.path.join(_path_wav, os.path.basename(root), os.path.splitext(name)[0] + ".wav")
#                if not os.path.exists(path_wav):
#                    continue
#                path_sdv = os.path.join(root, name)
#                lines = []
#                with open(path_sdv, "r", encoding="CP1251") as file_sdv:
#                    lines = file_sdv.readlines()
#                    file_sdv.close()
#                spkr_id = match.groups()[0]
#                sent_id = spkr_id + "_" + match.groups()[1]
#                self.append(FileInfo(root, name, path_wav, spkr_id, sent_id, Vocabulary(lines)))
#
#def CreateWavList(_path, _info_lst):
#    lines = StrList()
#    for info in _info_lst:
#        lines.Append(info.path)
#    lines.Save(_path)
#
#def CreateWavScp(_path, _info_lst):
#    lines = StrList()
#    for info in _info_lst:
#        lines.Append(info.sent + " " + info.path)
#    lines.Save(_path)
#
#def CreateWavTxt(_path, _info_lst):
#    lines = StrList()
#    for info in _info_lst:
#        lines.Append(info.sent + " " + info.text)
#    lines.Save(_path)
#
#def CreateUtt2Spk(_path, _info_lst):
#    lines = StrList()
#    for info in _info_lst:
#        lines.Append(info.sent + " " + info.spkr)
#    lines.Save(_path)
#
#def CreateLexicon(_path_lexicon, _path_lex_words, _info_lst):
#    lexicon = set([])
#    for info in _info_lst:
#        for word in info.vocb.words:
#            lexicon.add(word.text + " " + word.tran)
#    lines = StrList()
#    for line in lexicon:
#        lines.Append(line)
#    lines.Save(_path_lex_words)
#    lines.Append(g_word_sil + " " + g_phone_sil)
#    lines.Save(_path_lexicon)
#
#def CreatePhoneTable(_path, _info_lst):
#    phset = set([])
#    for info in _info_lst:
#        for word in info.vocb.words:
#            phones = word.tran.split(" ")
#            for phone in phones:
#                phset.add(phone)
#    phones = StrList()
#    for phone in phset:
#        phones.Append(phone)
#    phones.Save(_path)
#
#def CreateSilTables(_path_sil, _path_opt_sil):
#    silences = StrList()
#    silences.Append(g_phone_sil)
#    silences.Save(_path_sil)
#    silences.Save(_path_opt_sil)
#
#def CreateLangModel(_path, _info_lst):
#    wdset = set([])
#    for info in _info_lst:
#        for word in info.vocb.words:
#            wdset.add(word.text)
#    words = list(wdset)
#    words.sort()
#    with open(_path, "w", encoding="utf-8") as file_txt:
#        file_txt.write("\\data\\\n")
#        file_txt.write("ngram 1=" + str(len(words) + 2) + "\n")
#        file_txt.write("\\1-grams:\n")
#        file_txt.write("-99\t<s>\n")
#        file_txt.write("-1\t</s>\n")
#        for word in words:
#            file_txt.write("-1\t" + word + "\n")
#        file_txt.write("\\end\\\n")
#        file_txt.close()
#
#print("======= BEGIN =======")
#
#print("Рабочая директория: " + os.path.abspath(os.curdir))
#path_tmp = os.path.join(os.path.abspath(os.curdir), "wav")
#if not os.path.exists(path_tmp):
#    print("Директория не существует: " + path_tmp)
#    exit()
#path_tmp = "exp"
#if os.path.exists(path_tmp):
#    print("Удаление директории: " + path_tmp)
#    shutil.rmtree(path_tmp, True)
#path_tmp = "mfcc"
#if os.path.exists(path_tmp):
#    print("Удаление директории: " + path_tmp)
#    shutil.rmtree(path_tmp, True)
#g_data_dir = "data"
#if "data_dir" in os.environ:
#    g_data_dir = os.environ["data_dir"]
#if os.environ.has_key("data_dir"):
#    g_data_dir = os.environ["data_dir"]
#if os.path.exists(g_data_dir):
#    print("Удаление директории: " + g_data_dir)
#    shutil.rmtree(g_data_dir, True)
#print("Создание директории: " + g_data_dir)
#os.mkdir(g_data_dir)
#g_local_dir = os.path.join(g_data_dir, "local")
#print("Создание директории: " + g_local_dir)
#os.mkdir(g_local_dir)
#g_dict_dir = os.path.join(g_local_dir, "dict")
#print("Создание директории: " + g_dict_dir)
#os.mkdir(g_dict_dir)
#
#print("Загрузка sdv-файлов (train)...")
#g_train_lst = FileList()
#g_train_lst.Load("sent", os.path.join("wav", "train"))
#print(" Обучающая выборка: " + str(len(g_train_lst)) + " файлов.")
#print("Загрузка sdv-файлов (test)...")
#g_test_lst = FileList()
#g_test_lst.Load("sent", os.path.join("wav", "test"))
#print(" Тестовая выборка: " + str(len(g_test_lst)) + " файлов.")
#g_file_lst = g_train_lst + g_test_lst
#print("Всего загружено " + str(len(g_file_lst)) + " sdv-файлов.")
#
#print("Создание файла waves_all.list...")
#CreateWavList(os.path.join(g_local_dir, "waves_all.list"), g_file_lst)
#print("Создание файла waves.test...")
#CreateWavList(os.path.join(g_local_dir, "waves.test"), g_test_lst)
#print("Создание файла waves.train...")
#CreateWavList(os.path.join(g_local_dir, "waves.train"), g_train_lst)
#
#print("Создание файла test_wav.scp...")
#CreateWavScp(os.path.join(g_local_dir, "test_wav.scp"), g_test_lst)
#print("Создание файла train_wav.scp...")
#CreateWavScp(os.path.join(g_local_dir, "train_wav.scp"), g_train_lst)
#
#print("Создание файла test.txt...")
#CreateWavTxt(os.path.join(g_local_dir, "test.txt"), g_test_lst)
#print("Создание файла train.txt...")
#CreateWavTxt(os.path.join(g_local_dir, "train.txt"), g_train_lst)
#
#for data_set in [["test", g_test_lst], ["train", g_train_lst]]:
#    dir_dst = os.path.join(g_data_dir, data_set[0])
#    print("Создание директории: " + dir_dst)
#    os.mkdir(dir_dst)
#    print("Копирование файлов text и wav.scp...")
#    shutil.copyfile(os.path.join(g_local_dir, data_set[0] + ".txt"), os.path.join(dir_dst, "text"))
#    shutil.copyfile(os.path.join(g_local_dir, data_set[0] + "_wav.scp"), os.path.join(dir_dst, "wav.scp"))
#    print("Создание файла utt2spk...")
#    path_src = os.path.join(dir_dst, "utt2spk")
#    CreateUtt2Spk(path_src, data_set[1])
#    print("Создание файла spk2utt...")
#    path_dst = os.path.join(dir_dst, "spk2utt")
#    cmd_line = os.path.join(g_utils_dir, "utt2spk_to_spk2utt.pl") + " < " + path_src + " > " + path_dst
#    proc = os.popen(cmd_line)
#    for line in proc.readlines():
#        print(line)
#
#print("Создание файлов task.arpa и lm_test.arpa...")
#CreateLangModel(os.path.join(g_local_dir, "task.arpa"), g_test_lst)
#shutil.copyfile(os.path.join(g_local_dir, "task.arpa"), os.path.join(g_local_dir, "lm_test.arpa"))
#
#print("Создание файлов lexicon.txt и lexicon_words.txt...")
#CreateLexicon(os.path.join(g_dict_dir, "lexicon.txt"), os.path.join(g_dict_dir, "lexicon_words.txt"), g_file_lst)
#print("Создание файла nonsilence_phones.txt...")
#CreatePhoneTable(os.path.join(g_dict_dir, "nonsilence_phones.txt"), g_file_lst)
#print("Создание файлов silence_phones.txt и optional_silence.txt...")
#CreateSilTables(os.path.join(g_dict_dir, "silence_phones.txt"), os.path.join(g_dict_dir, "optional_silence.txt"))
#
#print("======= END =======")