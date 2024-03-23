#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/ref_counted.hpp>

#include <pybind11/pybind11.h>
#include <pybind11/embed.h>
#include <pybind11/functional.h>
#include <pybind11/stl.h>
namespace py = pybind11;


namespace godot {

	class GDExample : public RefCounted {
		GDCLASS(GDExample, RefCounted)

	protected:
		static void _bind_methods();

	public:
		GDExample();
		~GDExample();

		String pystrToString(py::object data);
		py::str StringTopystr(String data);

		String runPython(String path, String data);

	};

}

#endif