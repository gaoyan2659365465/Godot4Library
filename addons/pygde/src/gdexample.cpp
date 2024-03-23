#include "gdexample.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void GDExample::_bind_methods() {
	ClassDB::bind_method(D_METHOD("runPython","path","data"), &GDExample::runPython);
}

GDExample::GDExample() {
}

GDExample::~GDExample() {
	// Add your cleanup here.
}

String GDExample::pystrToString(py::object data) {
	std::wstring aaa = data.cast<std::wstring>();
	return String(aaa.c_str());
}

py::str GDExample::StringTopystr(String data) {
	std::string std_path(data.utf8().get_data());
	py::str py_path(std_path);
	return py_path;
}

String GDExample::runPython(String path,String data) {
	py::scoped_interpreter guard {};

	String result_value = "";

	py::module_ sys = py::module_::import("sys");
	sys.attr("path")
		.attr("append")(StringTopystr(path));
	try {
		py::module_ calc = py::module_::import("Main");
		py::object result = calc.attr("Main")(StringTopystr(data));
		result_value = pystrToString(result);
	}
	catch (py::error_already_set& e) {
		//py::print(e.type());
		//py::print(e.what());
		UtilityFunctions::print(String(py::str(e.type()).cast<std::string>().c_str()));
		UtilityFunctions::print(String(py::str(e.what()).cast<std::string>().c_str()));
		return result_value;
	}

	return result_value;
}