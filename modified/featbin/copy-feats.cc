// featbin/copy-feats.cc

// Copyright 2009-2011  Microsoft Corporation
//                2013  Johns Hopkins University (author: Daniel Povey)

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.

#include <map>
#include <algorithm>
#include <exception>
#include <boost/regex.hpp>
#include <boost/format.hpp>
#include <boost/filesystem.hpp>
#include <boost/algorithm/string.hpp>
#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "matrix/kaldi-matrix.h"

using namespace std;
using namespace kaldi;

class AverVect {
	public:
		typedef double value_t;
		typedef std::vector<value_t> array_t;
	protected:
		unsigned int dim;
		array_t aver;
		array_t dev;
		unsigned int num;
	public:
		AverVect(): dim(0), aver(), dev(), num(0) {}
		AverVect(unsigned int _dim): dim(_dim), aver(_dim, 0.0), dev(_dim, 0.0), num(0) {}
		void Init(unsigned int _dim) {dim = _dim; aver.assign(_dim, 0.0); dev.assign(_dim, 0.0); num = 0;}
		void Clear() {
			aver.assign(dim, 0.0);
			dev.assign(dim, 0.0);
			num = 0;
		}
		void Final() {
			if (num) {
				for (unsigned int i = 0; i < dim; ++i) {
					aver[i] /= num;
					dev[i] = dev[i] / num - aver[i] * aver[i];
					if (dev[i] > 0.0) {
						dev[i] = sqrt(dev[i]);
					} else {
						dev[i] = 0.0;
					}
				}
			}
		}
		const array_t& Aver() const {return aver;}
		const array_t& Dev() const {return dev;}
		unsigned int Dim() const {return dim;}
		unsigned int Num() const {return num;}
		double DistEuc(const AverVect& _vect) const {
			if (dim != _vect.dim) {
				throw std::runtime_error("AverVect::DistEuc() : this->dim != _vect.dim");
			}
			double dist = 0.0;
			for (unsigned int i = 0; i < dim; ++i) {
				const double diff = aver[i] - _vect.aver[i];
				dist += diff * diff;
			}
			return sqrt(dist);
		}
		double DistMah(const AverVect& _vect) const {
			if (dim != _vect.dim) {
				throw std::runtime_error("AverVect::DistMah() : this->dim != _vect.dim");
			}
			double dist = 0.0;
			for (unsigned int i = 0; i < dim; ++i) {
				const double diff = aver[i] - _vect.aver[i];
				dist += diff * diff / (dev[i] * _vect.dev[i]);
			}
			return sqrt(dist);
		}
		template<class Type>
		void Count(const Type* _vect, unsigned int _num) {
			for (unsigned int i = 0; i < dim; ++i) {
				aver[i] += _vect[i] * _num;
				dev[i] += _vect[i] * _vect[i] * _num;
			}
			num += _num;
		}
		template<class Type>
		void Count(const std::vector<Type>& _vect, unsigned int _num) {
			if (dim != _vect.size()) {
				throw std::runtime_error("AverVect::Count() : this->dim != _vect.size()");
			}
			for (unsigned int i = 0; i < dim; ++i) {
				aver[i] += _vect[i] * _num;
				dev[i] += _vect[i] * _vect[i] * _num;
			}
			num += _num;
		}
		template<class Type>
		void operator+=(const Type* _vect) {
			for (unsigned int i = 0; i < dim; ++i) {
				aver[i] += _vect[i];
				dev[i] += _vect[i] * _vect[i];
			}
			++num;
		}
		template<class Type>
		void operator+=(const std::vector<Type>& _vect) {
			if (dim != _vect.size()) {
				throw std::runtime_error("AverVect::operator+=() : this->dim != _vect.size()");
			}
			for (unsigned int i = 0; i < dim; ++i) {
				aver[i] += _vect[i];
				dev[i] += _vect[i] * _vect[i];
			}
			++num;
		}
		void operator+=(const AverVect& _vect) {
			if (dim != _vect.dim) {
				throw std::runtime_error("AverVect::operator+=() : this->dim != _vect.dim");
			}
			for (unsigned int i = 0; i < dim; ++i) {
				aver[i] += _vect.aver[i];
				dev[i] += _vect.dev[i];
			}
			num += _vect.num;
		}
};

void ReadDirectory(list<string>& _list, const char* _dir, const char* _ext) {
	boost::filesystem::recursive_directory_iterator iter(_dir);
	boost::filesystem::recursive_directory_iterator end;
	while(iter != end) {
		if (boost::filesystem::is_regular_file(*iter)) {
			if (boost::iequals(boost::filesystem::path(*iter).extension().string().c_str(), _ext)) {
				_list.push_back(boost::filesystem::path(*iter).string());
			}
		}
		iter++;
	}
}

class FtrFileMap: public map<string, string> {
	protected:
		typedef pair<string, string> info_t;

	public:
		void Load(const char* _dir) {
			clear();
			list<string> file_list;
			ReadDirectory(file_list, _dir, ".ftr");
			for (list<string>::const_iterator ipath = file_list.cbegin(); ipath != file_list.cend(); ++ipath) {
				insert(info_t(boost::filesystem::path(*ipath).stem().string(), *ipath));
			}
		}
};

bool LoadMatrix(const string& _path, Matrix<BaseFloat>& _matrix, size_t _vect_dim) {
	const size_t file_size = boost::filesystem::file_size(_path);
	const size_t vect_num = file_size / (_vect_dim * sizeof(BaseFloat));
	if (file_size == (vect_num * _vect_dim * sizeof(BaseFloat))) {
		_matrix.Resize(vect_num, _vect_dim, kaldi::MatrixResizeType::kSetZero);
		std::ifstream file(_path, std::ios_base::binary);
		if (file.good()) {
			vector<BaseFloat> buff(vect_num * _vect_dim, 0);
			file.read((char*) &buff.front(), file_size);
			const size_t stride = (size_t) _matrix.Stride();
			const BaseFloat* ftr_src_ptr = &buff.front();
			const BaseFloat* ftr_src_end = ftr_src_ptr + buff.size();
			BaseFloat* ftr_dst_ptr = _matrix.Data();
			const BaseFloat* ftr_dst_end = ftr_dst_ptr + vect_num * stride;
			for (size_t i = 0; i < vect_num; ++i, ftr_src_ptr += _vect_dim, ftr_dst_ptr += stride) {
				std::copy_n(ftr_src_ptr, _vect_dim, ftr_dst_ptr);
			}
			if (ftr_src_ptr != ftr_src_end) {
				return false;
			}
			if (ftr_dst_ptr != ftr_dst_end) {
				return false;
			}
			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

class FeatureConverter {
	protected:
		const char* dir_src;
		const char* dir_dst;
		const char* dir_mfcc[2];
		const char* ark_name[2];
		const size_t vect_dim;
		const size_t part_num;

	protected:
		AverVect aver_ark;
		AverVect aver_stc;

	public:
		FeatureConverter();
		void CalcStat(const Matrix<BaseFloat>& _matr, AverVect& _aver);
		bool CalcStat();
		bool Convert();
};

FeatureConverter::FeatureConverter():
	dir_src("g:\\temp\\mfcc"),
	dir_dst("g:\\temp\\mfcc_stc"),
	vect_dim(13),
	part_num(4)
{
	dir_mfcc[0] = "g:\\adatp\\ftr_mfcc_test";
	dir_mfcc[1] = "g:\\adatp\\ftr_mfcc_train";
	ark_name[0] = "raw_mfcc_test";
	ark_name[1] = "raw_mfcc_train";
}

void FeatureConverter::CalcStat(const Matrix<BaseFloat>& _matr, AverVect& _aver) {
	const size_t vect_num = (size_t) _matr.NumRows();
	const size_t vect_dim = (size_t) _matr.NumCols();
	const size_t stride = (size_t) _matr.Stride();
	if (_aver.Dim() == vect_dim) {
		const BaseFloat* ftr_ptr = _matr.Data();
		const BaseFloat* ftr_end = ftr_ptr + vect_num * stride;
		for (size_t i = 0; i < vect_num; ++i, ftr_ptr += stride) {
			_aver += ftr_ptr;
		}
		if (ftr_ptr != ftr_end) {
			cout << L"Error in FeatureConverter::CalcStat()." << endl;
		}
	} else {
		cout << L"Размерности вектора признаков и среднего не совпадают." << endl;
	}
}

bool FeatureConverter::CalcStat() {
	aver_ark.Init(vect_dim);
	aver_stc.Init(vect_dim);
	for (size_t i = 0; i < _countof(dir_mfcc); ++i) {
		FtrFileMap file_map;
		file_map.Load(dir_mfcc[i]);
		for (size_t j = 0; j < part_num; ++j) {
			const std::string name_ark = (boost::format("%1%.%2%.ark") % ark_name[i] % (j + 1)).str();
			const std::string rspecifier = std::string("ark:") + (boost::filesystem::path(dir_src) / name_ark).string();
			cout << name_ark << endl;
			SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
			while(!kaldi_reader.Done()) {
				const std::string utt = kaldi_reader.Key();
				CalcStat(kaldi_reader.Value(), aver_ark);
				FtrFileMap::const_iterator info = file_map.find(utt);
				if (info != file_map.end()) {
					Matrix<BaseFloat> matrix;
					if (LoadMatrix(info->second, matrix, vect_dim)) {
						CalcStat(matrix, aver_stc);
					} else {
						cout << L"Ошибка загрузки файла: " << info->second << std::endl;
					}
				} else {
					cout << L"Файл не найден: " << utt << std::endl;
				}
				kaldi_reader.Next();
			}
		}
	}
	aver_ark.Final();
	aver_stc.Final();
	cout << L"Подсчет статистики завершен." << endl;
	cout << L"Среднее (kaldi, stc):" << endl;
	for (size_t i = 0; i < aver_ark.Dim(); ++i) {
		cout << "  " << aver_ark.Aver()[i] << "  " << aver_stc.Aver()[i] << std::endl;
	}
	cout << L"Отношения среднеквадратичных отклонений (kaldi / stc):" << endl;
	for (size_t i = 0; i < aver_ark.Dim(); ++i) {
		cout << "  " << aver_ark.Dev()[i] / aver_stc.Dev()[i] << std::endl;
	}
	return true;
}

bool FeatureConverter::Convert() {
	for (size_t i = 0; i < _countof(dir_mfcc); ++i) {
		FtrFileMap file_map;
		file_map.Load(dir_mfcc[i]);
		for (size_t j = 0; j < part_num; ++j) {
			const std::string name_ark = (boost::format("%1%.%2%.ark") % ark_name[i] % (j + 1)).str();
			const std::string name_scp = (boost::format("%1%.%2%.scp") % ark_name[i] % (j + 1)).str();
			const std::string rspecifier = std::string("ark:") + (boost::filesystem::path(dir_src) / name_ark).string();
			const std::string wspecifier = std::string("ark,scp:") + (boost::filesystem::path(dir_dst) / name_ark).string() + "," + (boost::filesystem::path(dir_dst) / name_scp).string();
			cout << name_ark << endl;
			SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
			CompressedMatrixWriter kaldi_writer(wspecifier);
			while(!kaldi_reader.Done()) {
				const std::string utt = kaldi_reader.Key();
				FtrFileMap::const_iterator info = file_map.find(utt);
				if (info != file_map.end()) {
					Matrix<BaseFloat> matrix;
					if (LoadMatrix(info->second, matrix, vect_dim)) {
						kaldi_writer.Write(utt, CompressedMatrix(matrix));
					} else {
						cout << L"Ошибка загрузки файла: " << info->second << std::endl;
					}
				} else {
					cout << L"Файл не найден: " << utt << std::endl;
				}
				kaldi_reader.Next();
			}
		}
	}
	cout << L"Конвертирование файлов завершено." << endl;
	return true;
}

int main(int argc, char *argv[]) {
  try {
	/////////////////////////// DEBUG ///////////////////////////////
	////
	// ark:g:\temp\raw_mfcc_test.1.ark ark:g:\temp\raw_mfcc_test.1_.ark
	//const char* dir_src = "g:\\temp\\mfcc";
	//const char* dir_dst = "g:\\temp\\mfcc_stc";
	//const char* dir_mfcc[] = {"g:\\adatp\\ftr_mfcc_test", "g:\\adatp\\ftr_mfcc_train"};
	//const char* file_name[] = {"raw_mfcc_test", "raw_mfcc_train"};
	//const size_t vect_dim = 13;
	//const size_t part_num = 4;
	//for (size_t i = 0; i < _countof(dir_mfcc); ++i) {
	//	FtrFileMap file_map;
	//	file_map.Load(dir_mfcc[i]);
	//	for (size_t j = 0; j < part_num; ++j) {
	//		const std::string name_ark = (boost::format("%1%.%2%.ark") % file_name[i] % (j + 1)).str();
	//		const std::string name_scp = (boost::format("%1%.%2%.scp") % file_name[i] % (j + 1)).str();
	//		const std::string rspecifier = std::string("ark:") + (boost::filesystem::path(dir_src) / name_ark).string();
	//		const std::string wspecifier = std::string("ark,scp:") + (boost::filesystem::path(dir_dst) / name_ark).string() + "," + (boost::filesystem::path(dir_dst) / name_scp).string();
	//		cout << name_ark << endl;
	//		SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
	//		//BaseFloatMatrixWriter kaldi_writer(wspecifier);
	//		CompressedMatrixWriter kaldi_writer(wspecifier);
	//		while(!kaldi_reader.Done()) {
	//			const std::string utt = kaldi_reader.Key();
	//			const Matrix<BaseFloat>& matr(kaldi_reader.Value());
	//			const int32 vect_num = matr.NumRows();
	//			const int32 vect_dim = matr.NumCols();
	//			//std::cout << "utt: " << utt << " vect_num: " << vect_num << " vect_dim: " << vect_dim << std::endl;
	//			//kaldi_writer.Write(utt, matr);
	//			FtrFileMap::const_iterator info = file_map.find(utt);
	//			if (info != file_map.end()) {
	//				Matrix<BaseFloat> matrix;
	//				size_t stc_vect_num = 0;
	//				if (LoadMatrix(info->second, matrix, vect_dim, stc_vect_num)) {
	//					kaldi_writer.Write(utt, CompressedMatrix(matrix));
	//				} else {
	//					cout << L"Ошибка загрузки файла: " << info->second << std::endl;
	//				}
	//			} else {
	//				cout << L"Файл не найден: " << info->second << std::endl;
	//			}
	//			kaldi_reader.Next();
	//		}
	//	}
	//}
	//cout << L"Конвертирование файлов завершено." << endl;

	FeatureConverter ftr_conv;
	bool good = true;
	//good = ftr_conv.CalcStat();
	if (good) {
		good = ftr_conv.Convert();
	}
	
	return 0;
	////
	/////////////////////////////////////////////////////////////////

    const char *usage =
        "Copy features [and possibly change format]\n"
        "Usage: copy-feats [options] (<in-rspecifier> <out-wspecifier> | <in-rxfilename> <out-wxfilename>)\n";
    ParseOptions po(usage);
    bool binary = true;
    bool htk_in = false;
    bool sphinx_in = false;
    bool compress = false;
    po.Register("htk-in", &htk_in, "Read input as HTK features");
    po.Register("sphinx-in", &sphinx_in, "Read input as Sphinx features");
    po.Register("binary", &binary, "Binary-mode output (not relevant if writing "
                "to archive)");
    po.Register("compress", &compress, "If true, write output in compressed form"
                "(only currently supported for wxfilename, i.e. archive/script,"
                "output)");
    po.Read(argc, argv);
    if (po.NumArgs() != 2) {
      po.PrintUsage();
      exit(1);
    }
    int32 num_done = 0;
    if (ClassifyRspecifier(po.GetArg(1), NULL, NULL) != kNoRspecifier) {
      // Copying tables of features.
      std::string rspecifier = po.GetArg(1);
      std::string wspecifier = po.GetArg(2);

      if (!compress) {
        BaseFloatMatrixWriter kaldi_writer(wspecifier);
        if (htk_in) {
          SequentialTableReader<HtkMatrixHolder> htk_reader(rspecifier);
          for (; !htk_reader.Done(); htk_reader.Next(), num_done++)
            kaldi_writer.Write(htk_reader.Key(), htk_reader.Value().first);
        } else if (sphinx_in) {
          SequentialTableReader<SphinxMatrixHolder<> > sphinx_reader(rspecifier);
          for (; !sphinx_reader.Done(); sphinx_reader.Next(), num_done++)
            kaldi_writer.Write(sphinx_reader.Key(), sphinx_reader.Value());
        } else {
          SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
          for (; !kaldi_reader.Done(); kaldi_reader.Next(), num_done++)
            kaldi_writer.Write(kaldi_reader.Key(), kaldi_reader.Value());
        }
      } else {
        CompressedMatrixWriter kaldi_writer(wspecifier);
        if (htk_in) {
          SequentialTableReader<HtkMatrixHolder> htk_reader(rspecifier);
          for (; !htk_reader.Done(); htk_reader.Next(), num_done++)
            kaldi_writer.Write(htk_reader.Key(),
                               CompressedMatrix(htk_reader.Value().first));
        } else if (sphinx_in) {
          SequentialTableReader<SphinxMatrixHolder<> > sphinx_reader(rspecifier);
          for (; !sphinx_reader.Done(); sphinx_reader.Next(), num_done++)
            kaldi_writer.Write(sphinx_reader.Key(),
                               CompressedMatrix(sphinx_reader.Value()));
        } else {
          SequentialBaseFloatMatrixReader kaldi_reader(rspecifier);
          for (; !kaldi_reader.Done(); kaldi_reader.Next(), num_done++)
            kaldi_writer.Write(kaldi_reader.Key(),
                               CompressedMatrix(kaldi_reader.Value()));
        }
      }
      KALDI_LOG << "Copied " << num_done << " feature matrices.";
      return (num_done != 0 ? 0 : 1);
    } else {
      KALDI_ASSERT(!compress && "Compression not yet supported for single files");
      
      std::string feat_rxfilename = po.GetArg(1), feat_wxfilename = po.GetArg(2);

      Matrix<BaseFloat> feat_matrix;
      if (htk_in) {
        Input ki(feat_rxfilename); // Doesn't look for read binary header \0B, because
        // no bool* pointer supplied.
        HtkHeader header; // we discard this info.
        ReadHtk(ki.Stream(), &feat_matrix, &header);
      } else if (sphinx_in) {
        KALDI_ERR << "For single files, sphinx input is not yet supported.";
      } else {
        ReadKaldiObject(feat_rxfilename, &feat_matrix);
      }
      WriteKaldiObject(feat_matrix, feat_wxfilename, binary);
      KALDI_LOG << "Copied features from " << PrintableRxfilename(feat_rxfilename)
                << " to " << PrintableWxfilename(feat_wxfilename);
    }
  } catch(const std::exception &e) {
    std::cerr << e.what();
    return -1;
  }
	return 0;
}


